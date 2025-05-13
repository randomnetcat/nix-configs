{ config, lib, pkgs, name, nodes, ... }:

let
  host = "monitoring.unspecified.systems";
  prometheusPath = "prometheus";
  alertManagerPath = "alertmanager";

  # Map of host names to export names, for hosts using the export-metrics module.
  hostExports = lib.mapAttrs'
    (_: nodeConfig: {
      name = nodeConfig.config.networking.hostName;
      value = map (x: x.name) (lib.attrValues (lib.attrByPath [ "randomcat" "services" "export-metrics" "exports" ] [ ] nodeConfig.config));
    })
    (lib.filterAttrs (nodeName: nodeConfig: nodeName != name && (lib.attrByPath [ "randomcat" "services" "export-metrics" "enable" ] false nodeConfig.config) == true) nodes);

    alerts = {
      ScrapeDown = "ScrapeDown";
    };
in
{
  config = {
    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      webExternalUrl = "https://${host}/${prometheusPath}";
      webConfigFile = "/run/credentials/prometheus.service/prometheus-web";

      alertmanager = {
        enable = true;
        webExternalUrl = "https://${host}/${alertManagerPath}";
        checkConfig = false;

        configuration = {
          receivers = [
            {
              name = "default-receiver";

              discord_configs = [
                {
                  webhook_url = "$DISCORD_WEBHOOK_URL";
                }
              ];
            }
          ];

          route = {
            receiver = "default-receiver";

            group_by = [
              "alertname"
            ];

            routes = [
              {
                matchers = [
                  "alertname = ${alerts.ScrapeDown}"
                ];

                group_by = [
                  "alertname"
                  "hostname"
                ];
              }
            ];
          };
        };
      };

      exporters.node = {
        enable = true;
        port = 9100;
      };

      rules = [
        ''
          groups:
          - name: test
            rules:
            - alert: ${alerts.ScrapeDown}
              expr: up == 0
              for: 5m
              annotations:
                summary: "Host {{ $labels.hostname }} down"
        ''
      ];

      alertmanagers = [
        {
          basic_auth = {
            username = "prometheus";
            password_file = "/run/credentials/prometheus.service/prometheus-local-password";
          };

          path_prefix = "/${alertManagerPath}";

          static_configs = [
            {
              targets = [
                "localhost:${toString config.services.prometheus.alertmanager.port}"
              ];
            }
          ];
        }
      ];

      scrapeConfigs = [
        {
          job_name = "${config.networking.hostName}_node";
          static_configs = [
            {
              targets = [
                "localhost:${toString config.services.prometheus.exporters.node.port}"
              ];

              labels = {
                hostname = config.networking.hostName;
              };
            }
          ];
        }

        {
          job_name = "${config.networking.hostName}_prometheus";
          metrics_path = "/${prometheusPath}/metrics";

          basic_auth = {
            username = "local";
            password_file = "/run/credentials/prometheus.service/prometheus-local-password";
          };

          static_configs = [
            {
              targets = [
                "localhost:${toString config.services.prometheus.port}"
              ];

              labels = {
                hostname = config.networking.hostName;
              };
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

                labels = {
                  hostname = name;
                };
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

    systemd.services.alertmanager = {
      serviceConfig = {
        # Currently, alertmanager-web has passwords for two users: randomcat and prometheus.
        LoadCredentialEncrypted = [
          "alertmanager-web:${./secrets/alertmanager-web-config}"
        ];

        # We cannot use a credential path here, since systemd apparently reads the environment variable file
        # before setting up credentials.
        EnvironmentFile = "/run/keys/alertmanager-env";
      };
    };

    randomcat.services.fs-keys.alertmanager-creds = {
      requiredBy = [ "alertmanager.service" ];
      before = [ "alertmanager.service" ];

      keys.alertmanager-env = {
        source.encrypted.path = ./secrets/alertmanager-env;

        user = "root";
        group = "root";
        mode = "0400";
      };
    };

    services.nginx.virtualHosts."${host}" = {
      enableACME = true;
      forceSSL = true;

      locations."=/" = {
        return = "307 https://${host}/prometheus";
      };

      locations."/${prometheusPath}" = {
        recommendedProxySettings = true;
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
      };

      locations."/${alertManagerPath}" = {
        recommendedProxySettings = true;
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}";
      };
    };
  };
}
