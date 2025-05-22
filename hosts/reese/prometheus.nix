{ config, lib, pkgs, name, nodes, ... }:

let
  host = "monitoring.unspecified.systems";
  prometheusPath = "prometheus";
  alertManagerPath = "alertmanager";

  # Map of host names to export names, for hosts using the export-metrics
  # module.
  #
  # We handle exports from the current host separately.
  otherNodes = lib.removeAttrs nodes [ name ];
  enabledNodes = lib.filterAttrs (_: nodeConfig: nodeConfig.config.randomcat.services.export-metrics.enable or false) otherNodes;

  nodeExports = lib.mapAttrs (_: nodeConfig: map (export: export.name) (lib.attrValues (nodeConfig.config.randomcat.services.export-metrics.exports or { }))) enabledNodes;

  alertNames = [
    "BackupsOld"
    "ScrapeDownNonPortable"
    "ScrapeDownPortable"
  ];

  # This helps to prevent typos in the service configurations later.
  alerts = lib.genAttrs alertNames (x: x);

  portableHosts = lib.attrNames (lib.filterAttrs (n: v: v.isPortable) config.randomcat.network.hosts);
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

        extraFlags = [
          "--web.config.file=/run/credentials/alertmanager.service/alertmanager-web"
        ];

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
                  "alertname =~ ^(${alerts.ScrapeDownNonPortable}|${alerts.ScrapeDownPortable})$"
                ];

                group_by = [
                  "alertname"
                  "hostname"
                ];
              }

              {
                matchers = [
                  "alertname = ${alerts.BackupsOld}"
                ];

                group_by = [
                  "alertname"
                  "backup_group"
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
          - name: scrape_status
            rules:
            - alert: ${alerts.ScrapeDownNonPortable}
              expr: up{${lib.concatMapStringsSep "," (h: "hostname!=\"${h}\"") portableHosts}} == 0
              for: 5m
              annotations:
                summary: "Host {{ $labels.hostname }} down"
            - alert: ${alerts.ScrapeDownPortable}
              expr: ${lib.concatMapStringsSep " or " (h: "(up{hostname=\"${h}\"} == 0)") portableHosts}
              for: 48h
              annotations:
                summary: "Host {{ $labels.hostname }} down"
          - name: backups
            rules:
            - alert: ${alerts.BackupsOld}
              expr: '(time() - randomcat_zfs_backups_last_snapshot_timestamp_seconds) / (24 * 60 * 60) > 2'
              annotations:
                summary: "Backups for host {{ $labels.backup_group }} on {{ $labels.hostname }} are out of date (more than 2 days old)."
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
                  "${config.randomcat.network.hosts.${name}.tailscaleIP4}:9098"
                ];

                labels = {
                  hostname = name;
                };
              }
            ];
          })
          value)
        (lib.attrsToList nodeExports));
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
