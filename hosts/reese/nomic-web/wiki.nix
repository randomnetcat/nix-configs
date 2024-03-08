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
            
            extraConfig = ''
              AllowEncodedSlashes NoDecode
              RewriteEngine On
              RewriteRule "^${wikiSubpath}/rest.php$" "/rest.php" [PT]
              RewriteRule "^${wikiSubpath}/rest.php/(.*)$" "/rest.php/$1" [PT]
            '';
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
              url = "https://web.archive.org/web/20231227210041if_/https://extdist.wmflabs.org/dist/extensions/CodeMirror-REL1_41-f833cc4.tar.gz";
              sha256 = "sha256-Rg6ua5trCDuCSh3jLzrUhIxZXEKiTo5htrUprNAAV68=";
            };

            MobileFrontend = pkgs.fetchzip {
              url = "https://web.archive.org/web/20231227205620if_/https://extdist.wmflabs.org/dist/extensions/MobileFrontend-REL1_41-964152c.tar.gz";
              sha256 = "sha256-o7SQCW6VB2OB1h2H1xR2FNZv7Q5tjkqr8EdLRZC+VR8=";
            };

            DarkMode = pkgs.fetchzip {
              url = "https://web.archive.org/web/20231227205834if_/https://extdist.wmflabs.org/dist/extensions/DarkMode-REL1_41-0dfc34e.tar.gz";
              sha256 = "sha256-AHI+PyA4ufz3SiaQo6v0Ud27imWHfxJYpkZWG0PaR0Y=";
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

            // From https://www.mediawiki.org/wiki/Parsoid
            wfLoadExtension('Parsoid', "$IP/vendor/wikimedia/parsoid/extension.json");

            // SVG
            $wgSVGConverters = [
              'batik' => '${pkgs.jdk}/bin/java -Djava.awt.headless=true -jar ${pkgs.batik}/batik-rasterizer-${pkgs.batik.version}.jar -w $width -d $output $input'
            ];

            $wgSVGConverter = "batik";

            // External images
            $wgAllowExternalImagesFrom = [
              'https://nyhilo.website/cycle15/'
            ];
          '';
        };

        systemd.services.mediawiki-creds = {
          before = [ "mediawiki-init.service" ];
          requiredBy = [ "mediawiki-init.service" ];

          script = ''
            SECRET_DIR="$(mktemp -d)"
            install -m 0750 -o root -g keys -T -- "$CREDENTIALS_DIRECTORY/smtp-pass" "$SECRET_DIR/smtp-pass"
            install -m 0750 -o root -g keys -T -- "$CREDENTIALS_DIRECTORY/password-file" "$SECRET_DIR/password-file"
            mv -T -- "$SECRET_DIR/smtp-pass" /run/keys/smtp-pass
            mv -T -- "$SECRET_DIR/password-file" /run/keys/password-file
            rmdir -- "$SECRET_DIR"
          '';

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            PrivateTmp = true;
            LoadCredential = [ "smtp-pass" "password-file" ];
          };

          unitConfig.RequiresMountsFor = [ "/run/keys" ];
        };

        users.users.mediawiki.extraGroups = [ "keys" ];
      };

      ephemeral = false;
      autoStart = true;

      privateNetwork = true;

      hostAddress = containers.wiki.hostIP4;
      localAddress = containers.wiki.localIP4;
      hostAddress6 = containers.wiki.hostIP6;
      localAddress6 = containers.wiki.localIP6;

      extraFlags = [
        "--load-credential=smtp-pass:wiki-smtp-pass"
        "--load-credential=password-file:wiki-password-file"
        "-U"
      ];
    };

    systemd.services."container@wiki" = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          "wiki-smtp-pass:${../secrets/wiki-smtp-pass}"
          "wiki-password-file:${../secrets/wiki-password-file}"
        ];
      };
    };

    services.nginx.virtualHosts."${wikiHost}" = {
      enableACME = true;
      forceSSL = true;

      locations."${wikiSubpath}/".proxyPass = "http://[${containers.wiki.localIP6}]:${toString wikiPort}/";
      locations."${wikiSubpath}/rest.php/".proxyPass = "http://[${containers.wiki.localIP6}]:${toString wikiPort}/wiki/rest.php/";
      locations."=${wikiSubpath}/images/logo".alias = wikiLogo;
    };
  };
}
