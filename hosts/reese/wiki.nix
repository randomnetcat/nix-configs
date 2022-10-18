{ config, lib, pkgs, ... }:

let
  containers = import ./container-def.nix;
  wikiHost = "infinitenomic.randomcat.org";
  wikiPort = 8080;
  wikiSubpath = "/wiki"; # Subpath, either empty or starting but not ending with slash
  wikiLogo = "${./resources/infnom-wiki-logo.png}";
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
          name = "Infinite Nomic Wiki";

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
            $wgServer = 'https://${wikiHost}';
            $wgInternalServer = 'http://[${containers.wiki.localIP6}]:${toString wikiPort}';

            $wgCdnServersNoPurge = array();
            $wgCdnServersNoPurge[] = '${containers.wiki.hostIP6}';
            $wgUsePrivateIPs = true;
            $wgScriptPath = '${wikiSubpath}';
            $wgResourceBasePath = '${wikiSubpath}';
            $wgLogo = '${wikiSubpath}/images/logo';

            $wgEmergencyContact = 'admin@randomcat.org';
            $wgPasswordSender = 'infinitenomic-wiki@randomcat.org';

            $wgSMTP = [
              'host' => 'smtp.sendgrid.net',
              'IDHost' => 'randomcat.org',
              'localhost' => 'randomcat.org',
              'port' => 587,
              'auth' => true,
              'username' => 'apikey',
              'password' => trim(file_get_contents('/run/keys/smtp-pass')),
            ];

            $wgAllowHTMLEmail = true;
          '';
        };

        systemd.tmpfiles.rules = [
          "C /run/keys/password-file - - - - /host-keys/password-file"
          "z /run/keys/password-file 750 root keys - -"
          "C /run/keys/smtp-pass - - - - /host-keys/smtp-pass"
          "z /run/keys/smtp-pass 750 root keys - -"
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

      locations."${wikiSubpath}/".proxyPass = "http://[${containers.wiki.localIP6}]:${toString wikiPort}/";
      locations."=${wikiSubpath}/images/logo".alias = wikiLogo;
    };

    randomcat.secrets.secrets."wiki-password-file" = {
      encryptedFile = ./secrets/wiki-password-file;
      dest = "/run/keys/containers/wiki/password-file";
      owner = "root";
      group = "root";
      permissions = "700";
      realFile = true;
    };

    randomcat.secrets.secrets."wiki-smtp-pass" = {
      encryptedFile = ./secrets/wiki-smtp-pass;
      dest = "/run/keys/containers/wiki/smtp-pass";
      owner = "root";
      group = "root";
      permissions = "700";
      realFile = true;
    };
  };
}