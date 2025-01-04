{ config, lib, pkgs, ... }:

let
  types = lib.types;
  cfg = config.randomcat.mastodon-containers;
  enabledInstances = lib.filterAttrs (name: conf: conf.enable) cfg.instances;
  containers = import ../container-def.nix;
  instanceModule = { name, ... }: {
    options = {
      enable = lib.mkEnableOption "Mastodon instance container";

      instanceName = lib.mkOption {
        type = types.str;
        default = name;
      };

      containerName = lib.mkOption {
        type = types.str;
        default = "mastodon-" + name;
      };

      webDomain = lib.mkOption {
        type = types.str;
      };

      localDomain = lib.mkOption {
        type = types.str;
      };

      localIP4 = lib.mkOption {
        type = types.str;
        default = containers."mastodon-${name}".localIP4;
      };

      hostIP4 = lib.mkOption {
        type = types.str;
        default = containers."mastodon-${name}".hostIP4;
      };

      objectStorage = {
        enable = lib.mkEnableOption "S3-compatible object storage";

        aliasHost = lib.mkOption {
          type = types.str;
        };

        bucketName = lib.mkOption {
          type = types.str;
        };

        bucketRegion = lib.mkOption {
          type = types.str;
        };

        bucketHostname = lib.mkOption {
          type = types.str;
        };

        bucketEndpoint = lib.mkOption {
          type = types.str;
        };

        encryptedCredFile = lib.mkOption {
          type = types.path;
          description = "systemd encrypted credential file, decryptnig to a file in systemd env format with AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY";
        };
      };
    };
  };
in
{
  options = {
    randomcat.mastodon-containers.instances = lib.mkOption {
      type = types.attrsOf (types.submodule instanceModule);
      default = { };
    };
  };

  config = {
    services.nginx = lib.mkMerge (lib.concatMap
      (conf:
        let containerConfig = config.containers."${conf.containerName}".config; inherit (conf) localIP4; in [
          {
            virtualHosts."${conf.localDomain}" = {
              locations."/.well-known/webfinger" = {
                return = "301 https://${conf.webDomain}$request_uri";
                extraConfig = ''
                  add_header Access-Control-Allow-Origin "*";
                '';
              };
            };

            virtualHosts."${conf.webDomain}" = {
              forceSSL = true;
              enableACME = true;

              root = "${containerConfig.services.mastodon.package}/public/";

              extraConfig = ''
                add_header X-Clacks-Overhead "GNU Natalie Nguyen";
              '';

              locations."/" = {
                tryFiles = "$uri @proxy";
              };

              locations."/system/" = lib.mkIf (!conf.objectStorage.enable) {
                proxyPass = "http://${localIP4}";
              };

              locations."@proxy" = {
                proxyPass = "http://${localIP4}:${toString containerConfig.services.mastodon.webPort}";
                proxyWebsockets = true;
              };

              locations."/api/v1/streaming/" = {
                proxyPass = "http://${localIP4}/api/v1/streaming/";
                proxyWebsockets = true;
              };
            };
          }

          (lib.mkIf conf.objectStorage.enable {
            proxyCachePath."files-${conf.instanceName}" = {
              enable = true;
              keysZoneName = "files-${conf.instanceName}";
              maxSize = "1G";
              inactive = "7d";
            };

            # Taken from https://docs.joinmastodon.org/admin/optional/object-storage-proxy/
            virtualHosts."${conf.objectStorage.aliasHost}" = {
              forceSSL = true;
              enableACME = true;

              extraConfig = ''
                set $s3_backend 'https://${conf.objectStorage.bucketName}.${conf.objectStorage.bucketHostname}';
              '';

              locations."/".extraConfig = "
            limit_except GET {
              deny all;
            }

            resolver 8.8.8.8;
            proxy_set_header Host ${conf.objectStorage.bucketName}.${conf.objectStorage.bucketHostname};
            proxy_set_header Connection '';
            proxy_set_header Authorization '';
            proxy_hide_header Set-Cookie;
            proxy_hide_header 'Access-Control-Allow-Origin';
            proxy_hide_header 'Access-Control-Allow-Methods';
            proxy_hide_header 'Access-Control-Allow-Headers';
            proxy_hide_header x-amz-id-2;
            proxy_hide_header x-amz-request-id;
            proxy_hide_header x-amz-meta-server-side-encryption;
            proxy_hide_header x-amz-server-side-encryption;
            proxy_hide_header x-amz-bucket-region;
            proxy_hide_header x-amzn-requestid;
            proxy_ignore_headers Set-Cookie;
            proxy_pass $s3_backend$request_uri;
            proxy_intercept_errors off;

            proxy_cache files-${conf.instanceName};
            proxy_cache_valid 200 48h;
            proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
            proxy_cache_lock on;

            expires 1y;
            add_header Cache-Control public;
            add_header 'Access-Control-Allow-Origin' '*';
            add_header X-Cache-Status $upstream_cache_status;
            add_header X-Content-Type-Options nosniff;
            add_header Content-Security-Policy \"default-src 'none'; form-action 'none'\";
          ";
            };
          })
        ])
      (lib.attrValues enabledInstances));

    networking.nat.internalInterfaces = map (conf: "ve-${conf.containerName}") (lib.attrValues enabledInstances);

    containers = lib.mapAttrs'
      (name: conf: lib.nameValuePair conf.containerName (
        let inherit (conf) localDomain webDomain localIP4 hostIP4; in {
          config = ({ config, lib, pkgs, ... }: {
            imports = [
              ../../../sys/impl/fs-keys.nix
            ];

            config = {
              system.stateVersion = "22.05";

              networking.useHostResolvConf = false;
              networking.firewall.enable = false;

              services.resolved.enable = true;

              services.mastodon = {
                enable = true;
                inherit localDomain;
                trustedProxy = hostIP4;
                enableUnixSocket = false;
                streamingProcesses = 1;

                # Temporarily bump Mastodon to 4.2.6. This will automatically disable itself when the nixpkgs input reaches an updated version,
                # so it won't cause any problems in the future.
                package = lib.mkIf ((lib.hasPrefix "4.2." pkgs.mastodon.version) && (lib.versionOlder pkgs.mastodon.version "4.2.10")) (
                  pkgs.mastodon.overrideAttrs (oldAttrs: {
                    version = "4.2.10";

                    src = pkgs.fetchFromGitHub {
                      owner = "mastodon";
                      repo = "mastodon";
                      rev = "v4.2.10";
                      hash = "sha256-z3veI0CpZk6mBgygqXk8SN/5WWjy5VkKLxC7nOLnyZE=";
                    };
                  })
                );

                smtp = {
                  createLocally = false;
                  host = "mail.unspecified.systems";
                  port = 465;
                  user = "mastodon@unspecified.systems";
                  passwordFile = "/run/keys/smtp-pass";
                  authenticate = true;
                  fromAddress = "mastodon@unspecified.systems";
                };

                extraConfig = lib.mkMerge [
                  {
                    WEB_DOMAIN = webDomain;
                    BIND = localIP4;

                    SMTP_DOMAIN = "unspecified.systems";
                    SMTP_TLS = "true";
                  }

                  (lib.mkIf conf.objectStorage.enable {
                    S3_ENABLED = "true";
                    S3_BUCKET = conf.objectStorage.bucketName;
                    S3_REGION = conf.objectStorage.bucketRegion;
                    S3_HOSTNAME = conf.objectStorage.bucketHostname;
                    S3_ENDPOINT = conf.objectStorage.bucketEndpoint;
                    S3_ALIAS_HOST = conf.objectStorage.aliasHost;
                  })
                ];

                extraEnvFiles = lib.mkIf conf.objectStorage.enable [
                  "/run/keys/object-storage-keys"
                ];
              };

              services.nginx = {
                enable = true;
                recommendedProxySettings = true;

                virtualHosts."${webDomain}" = {
                  default = true;

                  locations."/system/".alias = lib.mkIf (!conf.objectStorage.enable) "/var/lib/mastodon/public-system/";

                  locations."/api/v1/streaming/" = {
                    proxyPass = "http://mastodon-streaming";
                    proxyWebsockets = true;
                  };
                };

                upstreams.mastodon-streaming = {
                  extraConfig = ''
                    least_conn;

                    # https://www.nginx.com/blog/avoiding-top-10-nginx-configuration-mistakes/#keepalive
                    keepalive ${toString (config.services.mastodon.streamingProcesses * 2)};
                  '';

                  servers =
                    builtins.listToAttrs (
                      map
                        (i: {
                          name = "unix:/run/mastodon-streaming/streaming-${toString i}.socket";
                          value = { };
                        })
                        (lib.range 1 config.services.mastodon.streamingProcesses)
                    );
                };
              };

              randomcat.services.fs-keys.mastodon-init-creds = {
                requiredBy = [ "mastodon-init-dirs.service" ];
                before = [ "mastodon-init-dirs.service" ];

                keys.smtp-pass = {
                  source.inherited = true;

                  user = "mastodon";
                  group = "keys";
                  mode = "0440";
                };

                keys.object-storage-keys = lib.mkIf conf.objectStorage.enable {
                  source.inherited = true;

                  user = "mastodon";
                  group = "keys";
                  mode = "0440";
                };
              };

              users.users.nginx.extraGroups = [
                "keys"
                "mastodon"
              ];

              users.users.mastodon.extraGroups = [
                "keys"
              ];
            };
          });

          ephemeral = false;
          autoStart = true;

          privateNetwork = true;

          allowedDevices = [{
            modifier = "rwm";
            node = "/dev/net/tun";
          }];

          hostAddress = hostIP4;
          localAddress = localIP4;

          extraFlags = lib.mkMerge [
            [
              "--load-credential=smtp-pass:mastodon-smtp-pass"
            ]
            (lib.mkIf conf.objectStorage.enable [
              "--load-credential=object-storage-keys:mastodon-${name}-object-storage-keys"
            ])
            [
              "-U"
            ]
          ];
        }
      ))
      enabledInstances;

    systemd.network.networks."10-ignore-mastodon-containers" = {
      matchConfig = {
        Name = lib.mapAttrsToList (_: conf: "ve-${conf.containerName}") enabledInstances;
      };

      linkConfig = {
        Unmanaged = true;
      };
    };

    systemd.services = lib.mapAttrs'
      (name: conf: lib.nameValuePair "container@${conf.containerName}" ({
        after = [ "network.target" ];

        serviceConfig = {
          LoadCredentialEncrypted = lib.mkMerge [
            [
              "mastodon-smtp-pass:${../secrets/mastodon-smtp-pass}"
            ]
            (lib.mkIf conf.objectStorage.enable [
              "mastodon-${name}-object-storage-keys:${conf.objectStorage.encryptedCredFile}"
            ])
          ];
        };
      }))
      enabledInstances;
  };
}
