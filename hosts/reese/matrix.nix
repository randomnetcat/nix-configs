{ config, lib, pkgs, ... }:

let
  baseHost = "nomic.randomcat.org";
  matrixHost = "matrix.nomic.randomcat.org";
  matrixContainerHostIP4 = "10.231.148.11";
  matrixContainerLocalIP4 = "10.231.149.11";
  matrixContainerHostIP6 = "fc00::a1f1";
  matrixContainerLocalIP6 = "fc00::b1f1";
  matrixListenPort = 8008;
in {
  config = {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "jason.e.cobb@gmail.com";

    services.nginx = {
      enable = true;

      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts = {
        "${baseHost}" = {
          enableACME = true;
          forceSSL = true;

          locations."= /.well-known/matrix/server".extraConfig =
            let
              # use 443 instead of the default 8448 port to unite
              # the client-server and server-server port for simplicity
              server = { "m.server" = "${matrixHost}:443"; };
            in ''
              add_header Content-Type application/json;
              return 200 '${builtins.toJSON server}';
            '';
          locations."= /.well-known/matrix/client".extraConfig =
            let
              client = {
                "m.homeserver" =  { "base_url" = "https://${matrixHost}:443"; };
                # "m.identity_server" =  { "base_url" = "https://vector.im"; };
              };
            # ACAO required to allow element-web on any URL to request this json file
            in ''
              add_header Content-Type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '${builtins.toJSON client}';
            '';
        };

        "${matrixHost}" = {
          enableACME = true;
          forceSSL = true;
          locations."/_matrix".proxyPass = "http://[${matrixContainerLocalIP6}]:${toString matrixListenPort}";
        };
      };
    };

    networking.nat.enable = true;
    networking.nat.externalInterface = "enp0s3";
    networking.nat.internalInterfaces = [ "ve-matrix" ];

    containers.matrix = {
      config = {
        system.stateVersion = "21.11";

        networking.useHostResolvConf = false;
        networking.firewall.enable = false;

        services.resolved.enable = true;

        services.matrix-synapse = {
          enable = true;

          extraConfigFiles = [ "/run/keys/matrix-secret-config" ];

          settings = {
            server_name = "${baseHost}";
            listeners = [
              {
                port = matrixListenPort;
                bind_addresses = [ "::" "0.0.0.0" ];
                type = "http";
                tls = false;
                x_forwarded = true;
                resources = [
                  {
                    names = [ "client" "federation" ];
                    compress = false;
                  }
                ];
              }
            ];
            allow_public_rooms_without_auth = true;
            allow_public_rooms_over_federation = true;
          };
        };

        services.postgresql.enable = true;
        services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
          CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
          CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
            TEMPLATE template0
            LC_COLLATE = "C"
            LC_CTYPE = "C";
        '';

        systemd.tmpfiles.rules = [
          "C /run/keys/matrix-secret-config - - - - /host-keys/matrix-secret-config"
          "z /run/keys/matrix-secret-config 750 root keys - -"
        ];

        users.users.matrix-synapse.extraGroups = [ "keys" ];
      };

      ephemeral = false;
      autoStart = true;

      bindMounts = {
        "/host-keys" = {
          hostPath = "/run/keys/containers/matrix";
          isReadOnly = true;
        };
      };

      privateNetwork = true;

      # Arbitray addresses
      hostAddress = matrixContainerHostIP4;
      localAddress = matrixContainerLocalIP4;
      hostAddress6 = matrixContainerHostIP6;
      localAddress6 = matrixContainerLocalIP6;
    };
  };
}
