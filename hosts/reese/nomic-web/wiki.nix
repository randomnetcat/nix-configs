{ config, lib, pkgs, ... }:

let
  containers = import ../container-def.nix;
  wikiHost = "infinite.nomic.space";
  wikiPort = 8080;
  wikiSubpath = "/wiki"; # Subpath, either empty or starting but not ending with slash
  wikiLogo = "${./resources/infnom-wiki-logo.png}";
in
{
  config = {
    networking.nat.internalInterfaces = [ "ve-wiki" ];

    containers.wiki = {
      config = { config, lib, pkgs, ... }: {
        system.stateVersion = "22.05";

        networking.useHostResolvConf = false;
        networking.firewall.enable = false;

        services.resolved.enable = true;

        services.mediawiki = {
          enable = true;
          name = "Infinite Nomic Wiki";

          httpd.virtualHost = {
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
            Cite = null;
            CiteThisPage = null;
            ParserFunctions = null;
            TextExtracts = null;
            VisualEditor = null;
            WikiEditor = null;

            CodeMirror = pkgs.fetchzip {
              url = "https://web.archive.org/web/20231102025732if_/https://extdist.wmflabs.org/dist/extensions/CodeMirror-REL1_40-817396c.tar.gz";
              sha256 = "MESclPvlMXt2pSIlCtTCF28vDLVMPHmnQtvLFGfbfXQ=";
            };

            MobileFrontend = pkgs.fetchzip {
              url = "https://web.archive.org/web/20231102025347if_/https://extdist.wmflabs.org/dist/extensions/MobileFrontend-REL1_40-2ece372.tar.gz";
              sha256 = "ulTXd7ubQ/4w/Xvs3VPxPKGLK+QdaIazDMIW/RiHpOI=";
            };

            DarkMode = pkgs.fetchzip {
              url = "https://web.archive.org/web/20231023234922if_/https://extdist.wmflabs.org/dist/extensions/DarkMode-REL1_40-a1c3e67.tar.gz";
              sha256 = "caPOiUYilMaIiPvI6OsgHR1/TFjih2YcejTgTNmbdE8=";
            };
          };

          skins = {
            MinervaNeue = "${config.services.mediawiki.package}/share/mediawiki/skins/MinervaNeue";
          };

          extraConfig = ''
            # $wgDebugLogFile = '/var/log/mediawiki/debug.log';

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
            $wgPasswordSender = 'wiki@unspecified.systems';

            $wgSMTP = [
              'host' => 'tls://mail.unspecified.systems',
              'IDHost' => 'unspecified.systems',
              'localhost' => 'unspecified.sytems',
              'port' => 465,
              'auth' => true,
              'username' => 'wiki@unspecified.systems',
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

            // SVG
            $wgSVGConverters = [
              'batik' => '${pkgs.jdk}/bin/java -Djava.awt.headless=true -jar ${pkgs.batik}/batik-rasterizer-${pkgs.batik.version}.jar -w $width -d $output $input'
            ];

            $wgSVGConverter = "batik";
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
      encryptedFile = ../secrets/wiki-password-file;
      dest = "/run/keys/containers/wiki/password-file";
      owner = "root";
      group = "root";
      permissions = "700";
      realFile = true;
    };

    randomcat.secrets.secrets."wiki-smtp-pass" = {
      encryptedFile = ../secrets/wiki-smtp-pass;
      dest = "/run/keys/containers/wiki/smtp-pass";
      owner = "root";
      group = "root";
      permissions = "700";
      realFile = true;
    };
  };
}
