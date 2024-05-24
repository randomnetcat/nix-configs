{ config, lib, pkgs, ... }:

let
  keyLocation = "/run/keys/keycloak-db-password";

  hostIP4 = "10.231.148.12";
  localIP4 = "10.231.149.12";
  hostIP6 = "fd50:fe53:b222:1::2";
  localIP6 = "fd50:fe53:b222:2::2";

  listenPort = 80;

  keycloakHost = "auth.unspecified.systems";
  webfingerHost = "unspecified.systems";

  tailscaleName = "bear";
  tailscaleIP = "100.85.165.130";
  tailscalePort = 82;
in
{
  config = {
    containers.keycloak = {
      config = { config, lib, pkgs, ... }: {
        system.stateVersion = "23.11";

        services.resolved.enable = true;
        networking.useHostResolvConf = false;

        services.postgresql.enable = true;

        services.keycloak = {
          enable = true;

          database = {
            type = "postgresql";
            createLocally = true;

            username = "keycloak";
            passwordFile = keyLocation;
          };

          settings = {
            hostname = keycloakHost;
            hostname-admin-url = "http://${tailscaleName}:${toString tailscalePort}/";
            http-port = listenPort;
            proxy-headers = "xforwarded";
            http-enabled = true;
          };
        };

        networking.firewall.allowedTCPPorts = [
          config.services.keycloak.settings.http-port
        ];

        systemd.services.keycloak-creds-init =
          let
            dependents = [
              "keycloak.service"
              "keycloakPostgreSQLInit.service"
              "keycloakMySQLInit.service"
            ];
          in
          {
            requiredBy = dependents;
            before = dependents;

            serviceConfig.LoadCredential = [
              "db-password"
            ];

            script = ''
              umask 077
              cp --no-preserve=ownership,mode -- "$CREDENTIALS_DIRECTORY/db-password" ${lib.escapeShellArg keyLocation}
              chown -- root:keys ${lib.escapeShellArg keyLocation}
              chmod -- 750 ${lib.escapeShellArg keyLocation}
            '';
          };
      };

      ephemeral = false;
      autoStart = true;

      privateNetwork = true;
      hostAddress = hostIP4;
      hostAddress6 = hostIP6;
      localAddress = localIP4;
      localAddress6 = localIP6;

      extraFlags = [
        "-U"
        "--load-credential=db-password:keycloak-db-password"
      ];
    };

    systemd.services."container@keycloak" = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          "keycloak-db-password:${../secrets/keycloak-db-password}"
        ];
      };
    };

    services.nginx =
      let
        proxyConfig = {
          recommendedProxySettings = true;
          proxyPass = "http://[${localIP6}]:${toString listenPort}";
        };

        publicPaths = [
          "/js"
          "/realms"
          "/resources"
          "= /robots.txt"
        ];

        accounts = [
          {
            user = "janet@unspecified.systems";
            realm = "members";
          }
        ];

        # *sigh*.
        #
        # $arg_resource is the value of the resource query parameter in the request. However,
        # this value is not percent-decoded, and we need to handle the @ or : in the resource
        # being percent-encoded. I was unable to convince nginx to decode it after a rewrite,
        # so instead we just send a redirect to the client, allowing nginx to process the new
        # request, where it is properly percent-decoded.
        #
        # Webfinger is needed for Tailscale to accept our identity provider, but is not provided
        # by Keycloak. So, we hardcode it for a specific set of accounts.

        webfingerConfig = {
          "= /.well-known/webfinger" = {
            extraConfig = ''
              return 307 /__webfinger/$arg_resource;
            '';
          };

          "~ ^/__webfinger/(acct:[^/]+@[^/]+)" = {
            root = pkgs.linkFarm "webfinger-entries" (lib.listToAttrs (map (acct: {
              name = "acct:${acct.user}";
              value = pkgs.writeText "webfinger-${acct.user}" ''
                {
                  "subject": "acct:${acct.user}",
                  "links": [
                    {
                      "rel": "http://openid.net/specs/connect/1.0/issuer",
                      "href": "https://auth.unspecified.systems/realms/${acct.realm}"
                    }
                  ]
                }
              '';
            }) accounts));

            tryFiles = "/$1 =404";

            extraConfig = ''
              add_header Content-Type application/json;
            '';
          };
        };
      in
      {
        virtualHosts = {
          "${keycloakHost}" = {
            forceSSL = true;
            enableACME = true;

            locations = (lib.genAttrs publicPaths (_: proxyConfig)) // webfingerConfig;
          };

          "${tailscaleName}" = {
            listen = [
              {
                addr = tailscaleIP;
                port = tailscalePort;
              }
            ];

            locations = {
              "/" = proxyConfig;
            } // webfingerConfig;
          };

          "${webfingerHost}" = {
            locations = webfingerConfig;
          };
        };
      };
  };
}
