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

          extensions = {
            # null -> use built-in plugin

            CodeEditor = null;
            CategoryTree = null;
            CiteThisPage = null;
            ParserFunctions = null;
            TextExtracts = null;
            VisualEditor = null;
            WikiEditor = null;

            CodeMirror = pkgs.fetchzip {
              url = "https://web.archive.org/web/20221021033350if_/https://extdist.wmflabs.org/dist/extensions/CodeMirror-REL1_38-2e3d6dd.tar.gz";
              sha256 = "Hp/4+tcHcKZXtwf2d2wfWAbw3Mmz1btRRCr+KAPL748=";
            };

            MobileFrontend = pkgs.fetchzip {
              url = "https://web.archive.org/web/20221030003242if_/https://extdist.wmflabs.org/dist/extensions/MobileFrontend-REL1_38-a2b388b.tar.gz";
              sha256 = "ItCefiM06Ye4KFMWj1X8HVeQK0ir2TMH4S66bfqPgbA=";
            };

            DarkMode = pkgs.fetchzip {
              url = "https://web.archive.org/web/20221030004052if_/https://extdist.wmflabs.org/dist/extensions/DarkMode-REL1_38-0fc14f5.tar.gz";
              sha256 = "w4LV0e6NKaaYJRn/O+LomaiEup733RW/l1wTptS6hRo=";
            };
          };

          skins = {
            MinervaNeue = pkgs.fetchzip {
              url = "https://web.archive.org/web/20221030004352if_/https://extdist.wmflabs.org/dist/skins/MinervaNeue-REL1_38-7825f1e.tar.gz";
              sha256 = "L2AiIG9xOQ/boQOGRFhu4aZ6ML3HjmsbFztlFerKhuQ=";
            };
          };

          extraConfig = ''
            $wgForceHTTPS = true;
            $wgServer = 'https://${wikiHost}';
            $wgInternalServer = 'http://[${containers.wiki.localIP6}]:${toString wikiPort}';

            $wgCdnServersNoPurge = array();
            $wgCdnServersNoPurge[] = '${containers.wiki.hostIP6}';
            $wgUsePrivateIPs = true;
            $wgScriptPath = '${wikiSubpath}';
            $wgResourceBasePath = '${wikiSubpath}';
            $wgRestPath = '${wikiSubpath}/rest.php';
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

            // CodeEditor
            $wgDefaultUserOptions['usebetatoolbar'] = 1; // user option provided by WikiEditor extension

            // CodeMirror
            $wgDefaultUserOptions['usecodemirror'] = 1;
            $wgCodeMirrorEnableBracketMatching = true;
            $wgCodeMirrorAccessibilityColors = true;
            $wgCodeMirrorLineNumberingNamespaces = null;

            // MobileFrontend
            $wgDefaultMobileSkin = 'minerva';

            // Parsoid (for VisualEditor)
            $wgVirtualRestConfig['modules']['parsoid'] = [
              'url' => $wgInternalServer . $wgRestPath,
            ];

            wfLoadExtension('Parosid', 'vendor/wikimedia/parsoid/extension.json');
          '';
        };

        services.mediawiki.virtualHost.extraConfig = ''
          AllowEncodedSlashes NoDecode
          RewriteEngine On
          RewriteRule "^${wikiSubpath}/rest.php$" "/rest.php" [PT]
          RewriteRule "^${wikiSubpath}/rest.php/(.*)$" "/rest.php/$1" [PT]
        '';

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
      locations."${wikiSubpath}/rest.php/".proxyPass = "http://[${containers.wiki.localIP6}]:${toString wikiPort}/wiki/rest.php/";
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
