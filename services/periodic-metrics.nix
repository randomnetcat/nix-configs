{ config, lib, pkgs, ... }:

let
  inherit (lib) types;

  cfg = config.randomcat.services.periodic-metrics;
  nodeExporterCfg = config.services.prometheus.exporters.node;

  metricsDir = "/run/periodic-metrics";
in
{
  options = {
    randomcat.services.periodic-metrics = {
      enable = lib.mkEnableOption "collection of metrics on a schedule";

      collectors = lib.mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            script = lib.mkOption {
              type = types.lines;
              description = ''
                A script that collects the appropriate metrics and prints the results, in
                [Prometheus metrics format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format)
                to standard output.
              '';
            };
          };
        });
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "textfile" ];

      extraFlags = [
        "--collector.textfile.directory=${metricsDir}/out"
      ];
    };

    assertions = [
      {
        assertion = !(lib.elem "textfile" nodeExporterCfg.disabledCollectors);
        message = "Periodic metrics are implemented using the node exporter's textfile collector, so the exporter must be enabled and the collector must not be disabled.";
      }
    ] ++ (
      map (name: {
        assertion = (lib.match "^[a-zA-Z0-9_-]+$" name) != null;
        message = "Collector name must match [a-zA-Z0-9_-]+, but got: ${name}";
      }) (lib.attrNames cfg.collectors)
    );

    users.users.periodic-metrics = {
      isSystemUser = true;
      group = config.users.groups.periodic-metrics.name;
    };

    users.groups.periodic-metrics = { };

    systemd.tmpfiles.settings.periodic-metrics = 
      let 
        dirConfig = {
          user = config.users.users.periodic-metrics.name;
          group = config.users.users.periodic-metrics.name;
          mode = "0755";
        };
      in
      {
        "${metricsDir}".d = dirConfig;
        "${metricsDir}/out".d = dirConfig;
      };

    systemd.services = lib.mkMerge (
      lib.mapAttrsToList
        (name: value: {
          "periodic-metrics-${name}" = {
            startAt = "*:0/15:00";

            serviceConfig = {
              DynamicUser = true;
              Type = "oneshot";

              RuntimeDirectory = "periodic-metrics-${name}";
              RuntimeDirectoryMode = "0700";

              ExecStart = [
                # Use writeShellApplication to enforce shellcheck.
                "${pkgs.writeShellScript "collect-impl-${name}" ''
                  set -eu -o pipefail
                  ${lib.escapeShellArg (lib.getExe (pkgs.writeShellApplication {
                    name = "collect-impl-${name}";
                    text = value.script;
                  }))} > "$RUNTIME_DIRECTORY/out.prom"
                ''}"

                # Run this privileged so that it can move the output to its destination.
                "+${pkgs.writeShellScript "collect-commit-${name}" ''
                  set -eu -o pipefail
                  mv -- "$RUNTIME_DIRECTORY/out.prom" ${lib.escapeShellArg "${metricsDir}/out/${name}.prom"}
                ''}"
              ];
            };
          };
        })
        cfg.collectors
    );
  };
}
