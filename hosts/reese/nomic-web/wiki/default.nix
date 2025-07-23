{ config, lib, pkgs, ... }:

let
  containers = import ../../container-def.nix;
  wikiHost = "infinite.nomic.space";
  wikiPort = 8080;
  wikiSubpath = "/wiki"; # Subpath, either empty or starting but not ending with slash
  wikiLogo = "${./logo.png}";
in
{
  config = {
    networking.nat.internalInterfaces = [ "ve-wiki" ];

    containers.wiki = {
      config = { config, options, lib, pkgs, ... }: {
        imports = [
          ../../../../sys/impl/fs-keys.nix
        ];

        config = {
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

            extensions =
              let
                builtinPluginNames = [
                  "CodeEditor"
                  "CategoryTree"
                  "Cite"
                  "CiteThisPage"
                  "ParserFunctions"
                  "TemplateData"
                  "TextExtracts"
                  "VisualEditor"
                  "WikiEditor"
                ];


                builtinPlugins = lib.genAttrs builtinPluginNames (_: null);

                mediawikiRelease = "REL" + (lib.concatStringsSep "_" (lib.take 2 (lib.splitString "." config.services.mediawiki.package.version)));

                versionedPlugins = lib.mapAttrs
                  (n: v: pkgs.fetchzip {
                    url = v.url;
                    hash = v.hash;
                  })
                  (builtins.fromJSON (builtins.readFile (./plugins/data + "/plugins-${mediawikiRelease}.json")));
              in
              builtinPlugins // versionedPlugins;

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

              // Temporarily prohibit registrations due to spam.
              $wgGroupPermissions['*']['createaccount'] = false;
            '';
          };

          randomcat.services.fs-keys.mediawiki-creds = {
            before = [ "mediawiki-init.service" ];
            requiredBy = [ "mediawiki-init.service" ];

            keys.smtp-pass = {
              source.inherited = true;
              user = config.users.users.mediawiki.name;
            };

            keys.password-file.source.inherited = true;
          };

          users.users.mediawiki.extraGroups = [ "keys" ];
        };
      };

      ephemeral = false;
      autoStart = true;

      privateUsers = "pick";

      privateNetwork = true;
      hostAddress = containers.wiki.hostIP4;
      localAddress = containers.wiki.localIP4;
      hostAddress6 = containers.wiki.hostIP6;
      localAddress6 = containers.wiki.localIP6;

      extraFlags = [
        "--load-credential=smtp-pass:wiki-smtp-pass"
        "--load-credential=password-file:wiki-password-file"
      ];
    };

    systemd.services."container@wiki" = {
      after = [ "network.target" ];

      serviceConfig = {
        LoadCredentialEncrypted = [
          "wiki-smtp-pass:${../../secrets/wiki-smtp-pass}"
          "wiki-password-file:${../../secrets/wiki-password-file}"
        ];
      };
    };

    services.nginx.virtualHosts."${wikiHost}" = {
      locations."${wikiSubpath}/".proxyPass = "http://[${containers.wiki.localIP6}]:${toString wikiPort}/";
      locations."${wikiSubpath}/rest.php/".proxyPass = "http://[${containers.wiki.localIP6}]:${toString wikiPort}/wiki/rest.php/";
      locations."=${wikiSubpath}/images/logo".alias = wikiLogo;
    };
  };
}
