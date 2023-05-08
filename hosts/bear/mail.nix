{ config, pkgs, lib, ... }:

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

    services.maddy = {
      enable = true;
      openFirewall = true;

      hostname = "mail.unspecified.systems";

      primaryDomain = "unspecified.systems";

      localDomains = [
        "unspecified.systems"
      ];

      tls = {
        loader = "file";

        certificates = [
          {
            keyPath = "/var/lib/acme/unspecified.systems/key.pem";
            certPath = "/var/lib/acme/unspecified.systems/cert.pem";
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
            optional_step file /etc/maddy/aliases
        }

        msgpipeline local_routing {
            # Insert handling for special-purpose local domains here.
            # e.g.
            # destination lists.example.org {
            #     deliver_to lmtp tcp://127.0.0.1:8024
            # }

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

            modify {
                replace_rcpt static {
                    entry abuse@unspecified.systems postmaster@unspecified.systems
                }
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

            source $(local_domains) {
                check {
                    authorize_sender {
                        prepare_email &local_rewrites
                        user_to_email identity
                    }
                }

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
            default_source {
                reject 501 5.1.8 "Non-local sender domain"
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
                    min_tls_level encrypted
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

    services.nginx.virtualHosts."mta-sts.unspecified.systems" = {
      addSSL = true;
      acmeRoot = config.security.acme.certs."unspecified.systems".webroot;
      useACMEHost = "unspecified.systems";

      locations."=/.well-known/mta-sts.txt".alias = pkgs.writeText "mta-sts.txt" ''
        version: STSv1
        mode: enforce
        max_age: 604800
        mx: mail.unspecified.systems
      '';
    };
  };
}
