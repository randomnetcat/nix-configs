{ config, lib, pkgs, ... }:

let
  containers = import ./container-def.nix;
  wikiHost = "wiki.randomcat.org";
  wikiPort = 8080;
in
{
  imports = [
    ./nginx.nix
  ];

  config = {
    networking.nat.internalInterfaces = [ "ve-wiki" ];

    containers.wiki = {
      config = {
        system.stateVersion = "22.05";

        networking.useHostResolvConf = false;
        networking.firewall.enable = false;

        services.resolved.enable = true;

        services.mediawiki = {
          enable = true;
          name = "Random Internet Cat Wiki";

          virtualHost = {
            hostName = wikiHost;
            adminAddr = "admin@randomcat.org";

            forceSSL = false;
            enableACME = false;

            listen = [
              {
                ip = containers.wiki.localIP6;
                port = wikiPort;
                ssl = false;
              }
            ];
          };

          passwordFile = "/run/keys/password-file";

          extraConfig = ''
            $wgForceHTTPS = true;
            $wgInternalServer = 'http://[${containers.wiki.localIP6}]:${toString wikiPort}';
          '';
        };

        systemd.tmpfiles.rules = [
          "C /run/keys/password-file - - - - /host-keys/password-file"
          "z /run/keys/password-file 750 root keys - -"
        ];

        users.users.mediawiki.extraGroups = [ "keys" ];
      };

      ephemeral = false;
      autoStart = true;

      bindMounts = {
        "/host-keys" = {
          hostPath = "/run/keys/containers/wiki";
          isReadOnly = true;
        };
      };

      privateNetwork = true;

      hostAddress = containers.wiki.hostIP4;
      localAddress = containers.wiki.localIP4;
      hostAddress6 = containers.wiki.hostIP6;
      localAddress6 = containers.wiki.localIP6;
    };

    services.nginx.virtualHosts."${wikiHost}" = {
      enableACME = true;
      forceSSL = true;

      locations."/".proxyPass = "http://[${containers.wiki.localIP6}]:${toString wikiPort}";

      # MediaWiki needs these headers in order to know that the original request
      # was HTTPS.
      extraConfig = ''
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
