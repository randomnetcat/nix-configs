{ config, lib, pkgs, ... }:

let
  types = lib.types;
  cfg = config.randomcat.services.backups.prune;
  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
in
{
  options = {
    randomcat.services.backups.prune = {
      enable = lib.mkEnableOption "Syncoid snapshot pruning";

      datasets = lib.mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            syncoidTags = lib.mkOption {
              type = types.listOf types.str;
              description = "The syncoid identifiers of the snapshots to prune";
            };
          };
        });
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mkMerge (map ({ name, value }: {
      "sync-prune-${lib.replaceStrings ["/"] ["-"] name}" = {
        wantedBy = [ "multi-user.target" ];
        startAt = "06:00";

        script = ''
          set -euo pipefail

          prune_dataset_snaps() {
              declare -r dataset="$1"
              declare -r prefix="$2"

              echo "Pruning dataset: $dataset" >&2

              # It's okay if grep returns no matches, so need to check exit status.
              #
              # Also, ignore the last two snapshots to ensure that the most recent
              # common ancestor is not accidentally destroyed.

              ${zfsBin} list -t snapshot -Ho name -s createtxg -s creation -- "$dataset" \
                  | (grep -F "$dataset@$prefix" || test "$?" = 1) \
                  | head -n -2 \
                  | {
                      while IFS="" read -r snapshot; do
                          # Refuse to ever destroy a snapshot not matching the pattern.
                          if [[ "$snapshot" != "$dataset@$prefix"* ]]; then
                              echo "Refusing to destroy snapshot: $snapshot"

                              # There's a bug here, completely exit.
                              exit 1
                          fi

                          ${zfsBin} destroy -v -- "$snapshot"
                      done
                  }
          }

          prune_recursive_snaps() {
              declare -r parent="$1"
              declare -r snapshot_prefix="$2"

              echo "Pruning recursively from: $parent" >&2

              ${zfsBin} list -t filesystem -rHo name -- "$parent" | {
                  while IFS="" read -r dataset; do
                      if [[ ( "$dataset" != "$parent" ) && ( "$dataset" != "$parent/"* ) ]]; then
                          echo "Refusing to prune dataset: $dataset"
                          exit 1
                      fi

                      prune_dataset_snaps "$dataset" "$snapshot_prefix"
                  done
              }
          }

          if ! ${lib.escapeShellArgs [ zfsBin "list" "-Ho" "name" name ]}; then
            printf "Dataset %s does not exists; not pruning.\n" ${lib.escapeShellArg name}
            exit 0
          fi

          ${lib.concatMapStringsSep
            "\n"
            (syncoidTag: ''
              ${lib.escapeShellArgs [
                "prune_recursive_snaps"
                name
                "syncoid_${syncoidTag}"
              ]}
            '')
            value.syncoidTags
          }
        '';
      };
    }) (lib.attrsToList cfg.datasets));
  };
}
