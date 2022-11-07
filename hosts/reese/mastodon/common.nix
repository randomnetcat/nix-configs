{ config, lib, pkgs, ... }:

let
  types = lib.types;
  cfg = config.randomcat.mastodon-containers;
  enabledInstances = lib.filterAttrs (name: conf: conf.enable) cfg.instances;
  containers = import ../container-def.nix;
  instanceModule = { name, ... }: {
    options = {
      enable = lib.mkEnableOption "Mastodon instance container";

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
    randomcat.secrets.secrets."mastodon-smtp-pass" = {
      encryptedFile = ../secrets/mastodon-smtp-pass;
      dest = "/run/keys/mastodon-common/smtp-pass";
      owner = "root";
      group = "root";
      permissions = "700";
      realFile = true;
    };

    services.nginx.virtualHosts = lib.mkMerge (map (conf: let containerConfig = config.containers."${conf.containerName}".config; inherit (conf) localIP4; in {
      "${conf.localDomain}" = {
        locations."/.well-known/webfinger".return = "301 https://${conf.webDomain}$request_uri";
      };

      "${conf.webDomain}" = {
        forceSSL = true;
        enableACME = true;

        root = "${containerConfig.services.mastodon.package}/public/";

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
    }) (lib.attrValues enabledInstances));

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
           host = "smtp.sendgrid.net";
            port = 587;
            user = "apikey";
            passwordFile = "/run/keys/smtp-pass";
            authenticate = true;
            fromAddress = "mastodon@randomcat.org";
          };

          extraConfig = {
            WEB_DOMAIN = webDomain;
            BIND = localIP4;
          };
        };

        services.nginx = {
          enable = true;

          virtualHosts."${webDomain}" = {
            default = true;
            locations."/system/".alias = "/var/lib/mastodon/public-system/";
          };
        };

        systemd.tmpfiles.rules = [
          "C /run/keys/smtp-pass - - - - /common-keys/smtp-pass"
          "z /run/keys/smtp-pass 750 root keys - -"
        ];

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
      };

      privateNetwork = true;

      hostAddress = hostIP4;
      localAddress = localIP4;
    })) enabledInstances;
  };
}
