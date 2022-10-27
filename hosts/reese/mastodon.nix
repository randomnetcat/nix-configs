{ config, lib, pkgs, ... }:

let
  containers = import ./container-def.nix;
  localDomain = "randomcat.org";
  webDomain = "mastodon.randomcat.org";
  containerConfig = containers.mastodon;
in
{
  imports = [
    ./nginx.nix
  ];

  config = {
    networking.nat.internalInterfaces = [ "ve-mastodon" ];

    containers.mastodon = {
      config = ({ config, ... }: {
        system.stateVersion = "22.05";

        networking.useHostResolvConf = false;
        networking.firewall.enable = false;

        services.resolved.enable = true;

        services.mastodon = {
          enable = true;
          inherit localDomain;
          trustedProxy = containerConfig.hostIP6;
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
            BIND = "[${containerConfig.localIP6}]";
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
          "C /run/keys/smtp-pass - - - - /host-keys/smtp-pass"
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
        "/host-keys" = {
          hostPath = "/run/keys/containers/mastodon";
          isReadOnly = true;
        };
      };

      privateNetwork = true;

      hostAddress = containerConfig.hostIP4;
      localAddress = containerConfig.localIP4;
      hostAddress6 = containerConfig.hostIP6;
      localAddress6 = containerConfig.localIP6;
    };

    services.nginx.virtualHosts."randomcat.org" = {
      locations."/.well-known/webfinger".return = "301 https://${webDomain}$request_uri";
    };

    services.nginx.virtualHosts."${webDomain}" = {
      forceSSL = true;
      enableACME = true;

      root = "${config.containers.mastodon.config.services.mastodon.package}/public/";

      locations."/" = {
        tryFiles = "$uri @proxy";
      };

      locations."/system/" = {
        proxyPass = "http://[${containerConfig.localIP6}]";
      };

      locations."@proxy" = {
        proxyPass = "http://[${containerConfig.localIP6}]:${toString config.services.mastodon.webPort}";
        proxyWebsockets = true;
      };

      locations."/api/v1/streaming/" = {
        proxyPass = "http://[${containerConfig.localIP6}]:${toString config.services.mastodon.streamingPort}/";
        proxyWebsockets = true;
      };
    };

    randomcat.secrets.secrets."mastodon-smtp-pass" = {
      encryptedFile = ./secrets/mastodon-smtp-pass;
      dest = "/run/keys/containers/mastodon/smtp-pass";
      owner = "root";
      group = "root";
      permissions = "700";
      realFile = true;
    };
  };
}
