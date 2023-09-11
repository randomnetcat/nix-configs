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

        encryptedKeyFile = lib.mkOption {
          type = types.path;
          description = "Encrypted file in systemd env format with AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY";
        };
      };
    };
  };
in
{
  options = {
    randomcat.mastodon-containers.instances = lib.mkOption {
      type = types.attrsOf (types.submodule instanceModule);
      default = {};
    };
  };

  config = {
    randomcat.secrets.secrets = lib.mkMerge [
      {
        "mastodon-smtp-pass" = {
          encryptedFile = ../secrets/mastodon-smtp-pass;
          dest = "/run/keys/mastodon-common/smtp-pass";
          owner = "root";
          group = "root";
          permissions = "700";
          realFile = true;
        };
      }

      (lib.mapAttrs' (n: v: lib.nameValuePair "mastodon-${n}-object-storage-keys" {
        encryptedFile = v.objectStorage.encryptedKeyFile;
        dest = "/run/keys/mastodon-instance/${n}/object-storage-keys";
        owner = "root";
        group = "root";
        permissions = "700";
        realFile = true;
      }) (lib.filterAttrs (n: v: v.objectStorage.enable) enabledInstances))
    ];

    services.nginx = lib.mkMerge (lib.concatMap (conf: let containerConfig = config.containers."${conf.containerName}".config; inherit (conf) localIP4; in [
      {
        virtualHosts."${conf.localDomain}" = {
          locations."/.well-known/webfinger".return = "301 https://${conf.webDomain}$request_uri";
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

          locations."/system/" = {
            proxyPass = "http://${localIP4}";
          };

          locations."@proxy" = {
            proxyPass = "http://${localIP4}:${toString containerConfig.services.mastodon.webPort}";
            proxyWebsockets = true;
          };

          locations."/api/v1/streaming/" = {
            proxyPass = "http://${localIP4}:${toString containerConfig.services.mastodon.streamingPort}/";
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

          locations."/".tryFiles = "$uri @s3";

          locations."@s3".extraConfig = "
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
    ]) (lib.attrValues enabledInstances));

    networking.nat.internalInterfaces = map (conf: "ve-${conf.containerName}") (lib.attrValues enabledInstances);

    containers = lib.mapAttrs' (name: conf: lib.nameValuePair conf.containerName (let inherit (conf) localDomain webDomain localIP4 hostIP4; in {
      config = ({ config, ... }: {
        system.stateVersion = "22.05";

        networking.useHostResolvConf = false;
        networking.firewall.enable = false;

        services.resolved.enable = true;

        services.mastodon = {
          enable = true;
          inherit localDomain;
          trustedProxy = hostIP4;
          enableUnixSocket = false;

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

          virtualHosts."${webDomain}" = {
            default = true;
            locations."/system/".alias = "/var/lib/mastodon/public-system/";
          };
        };

        # Use a unit instead of tmpfiles so that we can delay execution until
        # after all mounts are done.
        systemd.services.load-mastodon-host-keys = {
          requiredBy = [ "mastodon-init-dirs.service" ];
          before = [ "mastodon-init-dirs.service" ];

          unitConfig = {
            RequiresMountsFor = lib.mkMerge [
              [
                "/run/keys"
                "/common-keys"
              ]
              (lib.mkIf conf.objectStorage.enable ["/instance-keys"])
            ];

            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            umask 077

            load_key() {
              TARGET_PATH="/run/keys/$1"
              cp --no-preserve=mode,ownership -- "$2" "$TARGET_PATH"
              chown root:keys -- "$TARGET_PATH"
              chmod 750 -- "$TARGET_PATH"
            }

            load_key smtp-pass /common-keys/smtp-pass
            ${lib.optionalString conf.objectStorage.enable "load_key object-storage-keys /instance-keys/object-storage-keys"}
          '';
        };

        users.users.nginx.extraGroups = [
          "keys"
          "mastodon"
        ];

        users.users.mastodon.extraGroups = [
          "keys"
        ];
      });

      ephemeral = false;
      autoStart = true;

      bindMounts = {
        "/common-keys" = {
          hostPath = "/run/keys/mastodon-common";
          isReadOnly = true;
        };

        "/instance-keys" = lib.mkIf conf.objectStorage.enable {
          hostPath = "/run/keys/mastodon-instance/${name}";
          isReadOnly = true;
        };
      };

      privateNetwork = true;

      hostAddress = hostIP4;
      localAddress = localIP4;
    })) enabledInstances;
  };
}
