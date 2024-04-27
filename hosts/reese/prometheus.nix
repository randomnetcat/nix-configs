{ config, lib, pkgs, ... }:

let
  prometheusHost = "monitoring.randomcat.org";
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
          static_configs = [
            {
              targets = [
                "localhost:${toString config.services.prometheus.port}"
              ];
            }
          ];
        }
      ];
    };

    systemd.services.prometheus = {
      serviceConfig = {
        # prometheus-web-config: basic_auth_users
        LoadCredentialEncrypted = "prometheus-web:${./secrets/prometheus-web-config}";
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
