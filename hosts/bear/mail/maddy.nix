{ config, pkgs, lib, ... }:

let
  cfg = config.randomcat.services.mail;
  primary = cfg.primaryDomain;
  allDomains = [ primary ] ++ cfg.extraDomains;
  maddyIP = "192.168.166.100";
in
{
  config = {
    users.users.maddy.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [
      25
      465
      587
      993
      143
    ];

    systemd.network.netdevs."40-maddy" = {
      enable = true;

      netdevConfig = {
        Name = "maddy0";
        Kind = "dummy";
      };
    };

    systemd.network.networks."40-maddy" = {
      enable = true;

      matchConfig = {
        Name = "maddy0";
      };

      networkConfig = {
        Address = maddyIP;
      };
    };

    assertions = [
      {
        assertion = !(lib.elem 588 config.networking.firewall.allowedTCPPorts) && !((config.networking.firewall.interfaces ? maddy0) && (lib.elem 588 config.networking.firewall.interfaces.maddy0.allowedTCPPorts));
        message = "Port 588 is used for local SMTP communication and should not be exposed publicly";
      }
    ];

    # Allow connecting to the raw TCP port only from the agora-lists container.
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 588 -d ${maddyIP} -j nixos-fw-accept -i ve-agora-lists
    '';

    services.maddy = {
      enable = true;
      openFirewall = true;

      hostname = "mail.${primary}";

      primaryDomain = primary;

      localDomains = allDomains;

      tls = {
        loader = "file";

        certificates = [
          {
            keyPath = "/var/lib/acme/${primary}/key.pem";
            certPath = "/var/lib/acme/${primary}/cert.pem";
          }
        ];
      };

      config = ''
        ## Maddy Mail Server - default configuration file (2022-06-18)
        # Suitable for small-scale deployments. Uses its own format for local users DB,
        # should be managed via maddyctl utility.
        #
        # See tutorials at https://maddy.email for guidance on typical
        # configuration changes.

        # ----------------------------------------------------------------------------
        # Base variables

        ## Included from NixOS Config

        # ----------------------------------------------------------------------------
        # Local storage & authentication

        # pass_table provides local hashed passwords storage for authentication of
        # users. It can be configured to use any "table" module, in default
        # configuration a table in SQLite DB is used.
        # Table can be replaced to use e.g. a file for passwords. Or pass_table module
        # can be replaced altogether to use some external source of credentials (e.g.
        # PAM, /etc/shadow file).
        #
        # If table module supports it (sql_table does) - credentials can be managed
        # using 'maddyctl creds' command.

        auth.pass_table local_authdb {
            table sql_table {
                driver sqlite3
                dsn credentials.db
                table_name passwords
            }
        }

        # imapsql module stores all indexes and metadata necessary for IMAP using a
        # relational database. It is used by IMAP endpoint for mailbox access and
        # also by SMTP & Submission endpoints for delivery of local messages.
        #
        # IMAP accounts, mailboxes and all message metadata can be inspected using
        # imap-* subcommands of maddyctl utility.

        storage.imapsql local_mailboxes {
            driver sqlite3
            dsn imapsql.db
        }

        # ----------------------------------------------------------------------------
        # SMTP endpoints + message routing

        # Already set in NixOS config
        # hostname $(hostname)

        table.chain local_rewrites {
            optional_step regexp "(.+)\+(.+)@(.+)" "$1@$3"
            optional_step static {
                entry postmaster postmaster@$(primary_domain)
            }
            optional_step regexp "(postmaster|abuse|security)@(.+)" "postmaster@$(primary_domain)"
            optional_step regexp "(.+)@randomcat.gay" "janet@unspecified.systems"
            optional_step regexp "(.+)@randomcat.org" "janet@unspecified.systems"
            optional_step regexp "(.+)@jecobb.com" "janet@unspecified.systems"
            optional_step file /etc/maddy/aliases
        }

        msgpipeline local_routing {
            destination_in regexp "(agora-test(-(bounces\+.*|confirm\+.*|join|leave|owner|request|subscribe|unsubscribe))?@agora.nomic.space)" "$1" {
                deliver_to lmtp tcp://${config.containers.agora-lists.localAddress}:8024
            }

            destination postmaster $(local_domains) {
                modify {
                    replace_rcpt &local_rewrites
                }

                deliver_to &local_mailboxes
            }

            default_destination {
                reject 550 5.1.1 "User doesn't exist"
            }
        }

        msgpipeline full_routing {
            destination postmaster $(local_domains) {
                deliver_to &local_routing
            }

            default_destination {
                modify {
                    dkim $(primary_domain) $(local_domains) default
                }

                deliver_to &remote_queue
            }
        }

        smtp tcp://0.0.0.0:25 {
            limits {
                # Up to 20 msgs/sec across max. 10 SMTP connections.
                all rate 20 1s
                all concurrency 10
            }

            dmarc yes
            check {
                require_mx_record
                dkim
                spf
            }

            source $(local_domains) {
                reject 501 5.1.8 "Use Submission for outgoing SMTP"
            }
            default_source {
                destination postmaster $(local_domains) {
                    deliver_to &local_routing
                }
                default_destination {
                    reject 550 5.1.1 "User doesn't exist"
                }
            }
        }

        submission tls://0.0.0.0:465 tcp://0.0.0.0:587 {
            limits {
              # Up to 50 msgs/sec across any amount of SMTP connections.
                all rate 50 1s
            }

            auth &local_authdb

            source agora.nomic.space {
                check {
                    authorize_sender {
                        # Only check envelope for mailman
                        check_header no

                        prepare_email regexp "agora-test(-.+)?@agora.nomic.space" "mailman@agora.nomic.space"
                        user_to_email static {
                            entry "mailman@agora.nomic.space" "mailman@agora.nomic.space"
                            entry "django@agora.nomic.space" "django@agora.nomic.space"
                        }
                    }
                }

                deliver_to &full_routing
            }

            source ${lib.concatStringsSep " " (lib.filter (d: d != "agora.nomic.space") allDomains)} {
                check {
                    authorize_sender {
                        prepare_email &local_rewrites
                        user_to_email identity
                    }
                }

                deliver_to &full_routing
            }

            default_source {
                default_destination {
                    reject 501 5.1.8 "Non-local sender domain"
                }
            }
        }

        submission tcp://${maddyIP}:588 {
            limits {
                all rate 50 1s
            }

            # This endpoint is only accessible on localhost (as guaranteed by the firewall configuration above),
            # so it's safe to allow insecure plaintext authentication.
            insecure_auth true
            auth &local_authdb

            source agora.nomic.space {
                check {
                    authorize_sender {
                        # Only check envelope for mailman
                        check_header no

                        prepare_email regexp "agora-test(-.+)?@agora.nomic.space" "mailman@agora.nomic.space"
                        user_to_email static {
                            entry "mailman@agora.nomic.space" "mailman@agora.nomic.space"
                            entry "django@agora.nomic.space" "django@agora.nomic.space"
                        }
                    }
                }

                deliver_to &full_routing
            }

            default_source {
                destination_in regexp "(agora-test@agora.nomic.space)" "$1" {
                    check {
                        # Only the django user may use this ability
                        authorize_sender {
                            prepare_email regexp ".+" "django@agora.nomic.space"

                            user_to_email static {
                                entry "django@agora.nomic.space" "django@agora.nomic.space"
                            }
                        }
                    }

                    # Never, under any circumstances, allow it to route anywhere other than localhost
                    deliver_to &local_routing
                }

                default_destination {
                    reject 501 5.1.2 "Can only send to agora-test when using a non-local destinations"
                }
            }
        }

        target.remote outbound_delivery {
            limits {
                # Up to 20 msgs/sec across max. 10 SMTP connections
                # for each recipient domain.
                destination rate 20 1s
                destination concurrency 10
            }
            mx_auth {
                dane
                mtasts {
                    cache fs
                    fs_dir mtasts_cache/
                }
                local_policy {
                    # At least agoranomic.org does not support TLS
                    min_tls_level none
                    min_mx_level none
                }
            }
        }

        target.queue remote_queue {
            target &outbound_delivery

            autogenerated_msg_domain $(primary_domain)
            bounce {
                destination postmaster $(local_domains) {
                    deliver_to &local_routing
                }
                default_destination {
                    reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
                }
            }
        }

        # ----------------------------------------------------------------------------
        # IMAP endpoints

        imap tls://0.0.0.0:993 tcp://0.0.0.0:143 {
            auth &local_authdb
            storage &local_mailboxes
        }
      '';
    };
  };
}
