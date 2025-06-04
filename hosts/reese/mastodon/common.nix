{ config, lib, pkgs, ... }:

let
  types = lib.types;
  cfg = config.randomcat.services.mastodon;
in
{
  options = {
    randomcat.services.mastodon = {
      enable = lib.mkEnableOption "Mastodon instance container";

      webDomain = lib.mkOption {
        type = types.str;
      };

      localDomain = lib.mkOption {
        type = types.str;
      };

      smtp = {
        passwordEncryptedCredFile = config.fountain.lib.mkCredentialOption {
          name = "mastodon-smtp-pass";
          description = "Mastodon SMTP password";
        };
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

  config = lib.mkIf cfg.enable {
    services.nginx = lib.mkMerge [
      {
        virtualHosts."${cfg.localDomain}" = {
          locations."/.well-known/webfinger" = {
            return = "302 https://${cfg.webDomain}$request_uri";
            extraConfig = ''
              add_header Access-Control-Allow-Origin "*";
            '';
          };
        };

        virtualHosts."${cfg.webDomain}" = {
          forceSSL = true;
          enableACME = true;

          root = "${config.services.mastodon.package}/public/";

          extraConfig = ''
            add_header X-Clacks-Overhead "GNU Natalie Nguyen";
          '';

          locations."/" = {
            tryFiles = "$uri @proxy";
          };

          locations."/system/".alias = lib.mkIf (!cfg.objectStorage.enable) "/var/lib/mastodon/public-system/";

          locations."@proxy" = {
            proxyPass = "http://127.0.0.1:${toString config.services.mastodon.webPort}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };

          locations."/api/v1/streaming/" = {
            proxyPass = "http://mastodon-streaming";
            proxyWebsockets = true;
            recommendedProxySettings = true;
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
      }

      (lib.mkIf cfg.objectStorage.enable {
        proxyCachePath."files-mastodon" = {
          enable = true;
          keysZoneName = "files-mastodon";
          maxSize = "1G";
          inactive = "7d";
        };

        # Taken from https://docs.joinmastodon.org/admin/optional/object-storage-proxy/
        virtualHosts."${cfg.objectStorage.aliasHost}" = {
          forceSSL = true;
          enableACME = true;

          extraConfig = ''
            set $s3_backend 'https://${cfg.objectStorage.bucketName}.${cfg.objectStorage.bucketHostname}';
          '';

          locations."/".extraConfig = "
            limit_except GET {
              deny all;
            }

            resolver 8.8.8.8;
            proxy_set_header Host ${cfg.objectStorage.bucketName}.${cfg.objectStorage.bucketHostname};
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

            proxy_cache files-mastodon;
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
    ];

    services.mastodon = {
      enable = true;
      trustedProxy = "127.0.0.1";
      enableUnixSocket = false;
      streamingProcesses = 1;

      inherit (cfg) localDomain;

      smtp = {
        createLocally = false;
        host = "mail.unspecified.systems";
        port = 465;
        user = "mastodon@unspecified.systems";
        authenticate = true;
        fromAddress = "mastodon@unspecified.systems";

        # This is only used in mastodon-init-dirs.service, so we can use a credential path here.
        passwordFile = "/run/credentials/mastodon-init-dirs.service/mastodon-smtp-pass";
      };

      extraConfig = lib.mkMerge [
        {
          WEB_DOMAIN = cfg.webDomain;
          BIND = "127.0.0.1";

          SMTP_DOMAIN = "unspecified.systems";
          SMTP_TLS = "true";
        }

        (lib.mkIf cfg.objectStorage.enable {
          S3_ENABLED = "true";
          S3_BUCKET = cfg.objectStorage.bucketName;
          S3_REGION = cfg.objectStorage.bucketRegion;
          S3_HOSTNAME = cfg.objectStorage.bucketHostname;
          S3_ENDPOINT = cfg.objectStorage.bucketEndpoint;
          S3_ALIAS_HOST = cfg.objectStorage.aliasHost;
        })
      ];

      extraEnvFiles = lib.mkIf cfg.objectStorage.enable [
        "/run/keys/mastodon-object-storage-keys"
      ];
    };

    systemd.services.mastodon-init-dirs = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          "mastodon-smtp-pass:${cfg.smtp.passwordEncryptedCredFile}"
        ];
      };
    };

    randomcat.services.fs-keys.mastodon-init-creds = {
      requiredBy = [ "mastodon-init-dirs.service" ];
      before = [ "mastodon-init-dirs.service" ];

      keys.mastodon-object-storage-keys = lib.mkIf cfg.objectStorage.enable {
        source.encrypted.path = cfg.objectStorage.encryptedCredFile;

        user = "root";
        group = "root";
        mode = "0400";
      };
    };

    # In order to allow access to /run/mastodon-streaming.
    users.users.nginx.extraGroups = [
      config.users.users.mastodon.name
    ];
  };
}
