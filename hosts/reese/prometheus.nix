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
      webConfigFile = "/run/credentials/prometheus.service/prometheus-web";

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
            password_file = "/run/credentials/prometheus.service/prometheus-local-password";
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
        LoadCredentialEncrypted = [
          "prometheus-local-password:${./secrets/prometheus-local-password}"
          "prometheus-web:${./secrets/prometheus-web-config}"
        ];
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
  };
}
