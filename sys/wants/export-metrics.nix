{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.export-metrics;
  inherit (lib) types;
in
{
  options = {
    randomcat.services.export-metrics = {
      enable = lib.mkEnableOption "exporting Prometheus metrics to the network";

      listenAddress = lib.mkOption {
        type = types.str;
        description = "The address to listen on.";
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = types.port;
        description = "The port to expose all metrics on.";
        default = 9098;
      };

      exports = lib.mkOption {
        type = types.attrsOf (types.submodule ({ lib, name, ... }: {
          options = {
            name = lib.mkOption {
              type = types.str;
              description = "The name of the exporter.";
              default = name;
            };

            localPort = lib.mkOption {
              type = types.nullOr types.port;
              description = "The port that the exporter is listening on locally. If enableService is set, this must not be set and will automatically be the port of the underlying exporter.";
              default = null;
            };

            enableService = lib.mkOption {
              type = types.bool;
              description = "Whether to enable the underlying service in services.prometheus.exporters.";
              default = true;
            };
          };
        }));
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = map
      ({ name, value }: {
        assertion = value.enableService -> value.localPort == null;
        message = "In randomcat.services.export-metrics.exports.${name}: localPort must not be set if enableService is true.";
      })
      (lib.attrsToList cfg.exports);

    services.prometheus.exporters = lib.mkMerge (map
      (value: {
        "${value.name}" = {
          enable = true;

          # We are exporting here. So, by default, there should be no reason to allow these metrics to be accessed anywhere else.
          listenAddress = lib.mkDefault "127.0.0.1";
        };
      })
      (lib.filter (value: value.enableService) (lib.attrValues cfg.exports)));

    services.nginx = {
      enable = true;

      virtualHosts."${cfg.listenAddress}" = {
        listen = [
          {
            addr = cfg.listenAddress;
            port = cfg.port;
          }
        ];

        default = true;

        locations = lib.mkMerge (map
          (value: {
            "=/export-metrics/${value.name}" = {
              recommendedProxySettings = true;
              proxyPass = "http://127.0.0.1:${toString (if value.enableService then config.services.prometheus.exporters."${value.name}".port else value.localPort)}/metrics";
            };
          })
          (lib.attrValues cfg.exports));
      };
    };
  };
}
