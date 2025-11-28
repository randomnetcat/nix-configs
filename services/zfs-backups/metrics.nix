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
  imports = [
    ../periodic-metrics.nix
  ];

  options = {
    randomcat.services.backups.target = {
      enableMetrics = lib.mkEnableOption "backup target metrics";
    };
  };

  config = lib.mkIf (targetCfg.enable && targetCfg.enableMetrics) {
    randomcat.services.periodic-metrics = lib.mkIf hasAnyMovements {
      enable = true;

      collectors.zfs-backups.script = ''
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

        echo "# HELP $metric_name The Unix timestamp of the last snapshot in the backed-up dataset."
        echo "# TYPE $metric_name gauge"

        ${lib.concatMapStringsSep "\n" (movement: ''
          ${lib.escapeShellArgs [
            "produce_movement"
            movement.name
            movement.targetFullDataset
          ]}
        '') movements}
      '';
    };
  };
}
