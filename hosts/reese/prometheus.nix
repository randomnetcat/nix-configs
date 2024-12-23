{ config, lib, pkgs, name, nodes, ... }:

let
  prometheusHost = "monitoring.randomcat.org";

  # Map of host names to export names, for hosts using the export-metrics module.
  hostExports = lib.mapAttrs'
    (_: nodeConfig: {
      name = nodeConfig.config.networking.hostName;
      value = map (x: x.name) (lib.attrValues (lib.attrByPath [ "randomcat" "services" "export-metrics" "exports" ] [ ] nodeConfig.config));
    })
    (lib.filterAttrs (nodeName: nodeConfig: nodeName != name && (lib.attrByPath [ "randomcat" "services" "export-metrics" "enable" ] false nodeConfig.config) == true) nodes);
in
{
  config = {
    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      webExternalUrl = "https://${prometheusHost}";

      # Cannot use webConfigFile because that requires a nix path (rather than a string).
      extraFlags = [ "--web.config.file=\"\${CREDENTIALS_DIRECTORY}/prometheus-web\"" ];

      exporters.node = {
        enable = true;
        port = 9100;
      };

      scrapeConfigs = [
        {
          job_name = "${config.networking.hostName}_node";
          static_configs = [
            {
              targets = [
                "localhost:${toString config.services.prometheus.exporters.node.port}"
              ];
            }
          ];
        }

        {
          job_name = "${config.networking.hostName}_prometheus";

          basic_auth = {
            username = "local";
            password_file = "/run/keys/prometheus-local-password";
          };

          static_configs = [
            {
              targets = [
                "localhost:${toString config.services.prometheus.port}"
              ];
            }
          ];
        }
      ] ++ (lib.concatMap
        ({ name, value }: map
          (exporter: {
            job_name = "${name}_${exporter}";
            metrics_path = "/export-metrics/${exporter}";

            static_configs = [
              {
                targets = [
                  "${name}:9098"
                ];
              }
            ];
          })
          value)
        (lib.attrsToList hostExports));
    };

    systemd.services.prometheus = {
      serviceConfig = {
        # prometheus-web-config: basic_auth_users
        LoadCredentialEncrypted = "prometheus-web:${./secrets/prometheus-web-config}";

        # Allow access to /run/keys
        SupplementaryGroups = [ "keys" ];
      };
    };

    services.nginx.virtualHosts."${prometheusHost}" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        recommendedProxySettings = true;
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
      };
    };

    randomcat.services.fs-keys.prometheus-creds = {
      before = [ "prometheus.service" ];
      wantedBy = [ "prometheus.service" ];

      keys.prometheus-local-password = {
        user = config.users.users.prometheus.name;
        source.encrypted.path = ./secrets/prometheus-local-password;
      };
    };
  };
}
