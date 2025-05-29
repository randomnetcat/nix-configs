{ config, lib, pkgs, ... }:

let
  targetCfg = config.randomcat.services.backups.target;
  nodeExporterCfg = config.services.prometheus.exporters.node;

  movements = lib.attrValues targetCfg.movements;
  hasAnyMovements = lib.length movements > 0;

  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
  runtimeDirName = "randomcat-backup-metrics";
in
{
  options = {
    randomcat.services.backups.target = {
      enableMetrics = lib.mkEnableOption "backup target metrics";
    };
  };

  config = lib.mkIf (targetCfg.enable && targetCfg.enableMetrics) {
    assertions = [
      {
        assertion = nodeExporterCfg.enable && !(lib.elem "textfile" nodeExporterCfg.disabledCollectors);
        message = "Backup target metrics are implemented using the node exporter's textfile collector, so the exporter must be enabled and the collector must not be disabled.";
      }
    ];
    
    # Unfortunately, we have to create a dedicated user/group for this if we don't want to run the service as root.
    # We can't use DynamicUser because then the node exporter service can't read the RuntimeDirectory.
    users.users.backup-metrics = {
      isSystemUser = true;
      group = config.users.groups.backup-metrics.name;
    };

    users.groups.backup-metrics = { };

    services.prometheus.exporters.node.extraFlags = lib.mkIf hasAnyMovements [
      "--collector.textfile.directory=/run/${runtimeDirName}"
    ];

    systemd.services.randomcat-backup-metrics = lib.mkIf hasAnyMovements {
      serviceConfig = {
        RuntimeDirectory = runtimeDirName;
        RuntimeDirectoryMode = "0755";
        # Keep the runtime directory around so that the node exporter can reed it.
        RuntimeDirectoryPreserve = true;

        Type = "oneshot";
        User = config.users.users.backup-metrics.name;
        Group = config.users.groups.backup-metrics.name;
      };

      startAt = "*:0/15:00";

      # No need to have an ordering dependency. Any changes will be picked up once this service finishes.
      wantedBy = [ "prometheus-node-exporter.service" ];

      enableStrictShellChecks = true;

      script = ''
        set -eu -o pipefail

        metric_name="randomcat_zfs_backups_last_snapshot_timestamp_seconds"

        produce_movement() {
          local movement_name="$1"
          local movement_dataset="$2"

          ${zfsBin} list -Hr -o name -- "$movement_dataset" | while IFS="" read -r child_dataset; do
            local last_snapshot
            last_snapshot="$(${zfsBin} list -Hp -t snapshot -o creation -- "$child_dataset" | tail -n 1)"

            if [[ -z "$last_snapshot" ]]; then
              echo "Found no snapshot time for $child_dataset?" 1>&2
              continue
            fi

            printf '%s{movement="%s",dataset="%s"} %s\n' "$metric_name" "$movement_name" "$child_dataset" "$last_snapshot"
          done
        }

        produce_file() {
          echo "# HELP $metric_name The Unix timestamp of the last snapshot in the backed-up dataset."
          echo "# TYPE $metric_name gauge"

          ${lib.concatMapStringsSep "\n" (movement: ''
            ${lib.escapeShellArgs [
              "produce_movement"
              movement.name
              movement.targetFullDataset
            ]}
          '') movements}
        }

        # This idiom is suggested by the node exporter README.
        final_out="$RUNTIME_DIRECTORY/backups.prom"
        work_out="$final_out.$$"

        cleanup() {
          rm -f -- "$work_out"
        }

        trap cleanup EXIT

        produce_file > "$work_out"
        mv -T -- "$work_out" "$final_out"
      '';
    };
  };
}
