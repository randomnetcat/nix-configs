{ config, lib, pkgs, ... }:

let
  types = lib.types;

  childPerms = "create,mount,bookmark,hold,receive,snapshot";
  zfsBin = lib.getExe' config.boot.zfs.package "zfs";

  cfg = config.randomcat.services.backups;
  targetParent = cfg.target.parentDataset;
in
{
  options = {
    randomcat.services.backups.target = {
      enable = lib.mkEnableOption "Backups destination";

      parentDataset = lib.mkOption {
        type = types.str;
        description = "The parent dataset under which to store backups from other hosts";
      };

      acceptSources = lib.mkOption {
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
          options = {
            name = lib.mkOption {
              type = types.str;
              description = "The name of the host";
            };

            user = lib.mkOption {
              type = types.str;
              description = "The name of the username to accept for backups";
            };

            sshKey = lib.mkOption {
              type = types.nullOr types.str;
              description = "The SSH key to add to the user";
              default = null;
            };

            childDataset = lib.mkOption {
              type = types.str;
              description = "The name of the child dataset to grant access to";
            };

            fullDataset = lib.mkOption {
              type = types.str;
              description = "The full name of the destination dataset";
              internal = true;
            };

            syncoidTag = lib.mkOption {
              type = types.str;
              description = "The tag that syncoid uses in sync snapshots for this source";
            };
          };

          config = {
            name = lib.mkDefault name;
            user = lib.mkDefault ("sync-" + config.name);
            childDataset = lib.mkDefault config.name;
            fullDataset = "${targetParent}/${config.childDataset}";
            syncoidTag = lib.mkDefault config.name;
          };
        }));

        description = "Descriptions of sources that this destination host should be prepared to accept backups from";
      };
    };
  };

  config = let
    destTargetBaseName = "sync-dest";
    destTargetName = "${destTargetBaseName}.target";

    destTarget = {
      wantedBy = [ "multi-user.target" ];
    };

    mkCreateDatasetService = sourceCfg: {
      wantedBy = [ destTargetName ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -euo pipefail

        if ${lib.escapeShellArgs [ zfsBin "list" "-Ho" "name" sourceCfg.fullDataset ]}; then
          printf "Dataset %s already exists; not creating.\n" ${lib.escapeShellArg sourceCfg.fullDataset}
          exit 0
        fi

        ${lib.escapeShellArgs [ zfsBin "create" sourceCfg.fullDataset ]}

        printf "Created dataset %s\n" ${lib.escapeShellArg sourceCfg.fullDataset}
      '';
    };

    mkAcceptPermsService = sourceCfg: {
      wantedBy = [ destTargetName ];

      requires = [ "sync-create-${sourceCfg.name}.service" ];
      after = [ "sync-create-${sourceCfg.name}.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -eu

        ${lib.escapeShellArgs [
          zfsBin
          "allow"
          "-u"
          sourceCfg.user
          childPerms
          sourceCfg.fullDataset
        ]} || printf "Could not grant permissions on dataset %s for user %s; ignoring.\n" ${lib.escapeShellArgs [sourceCfg.user sourceCfg.fullDataset]}
      '';

      postStop = ''
        ${lib.escapeShellArgs [
          zfsBin
          "unallow"
          "-u"
          sourceCfg.user
          sourceCfg.fullDataset
        ]} || printf "Could not revoke permissions on dataset %s from user %s; ignoring.\n" ${lib.escapeShellArgs [sourceCfg.user sourceCfg.fullDataset]}
      '';
    };

    mkPruneSyncSnapsService = sourceCfg: {
      wantedBy = [ destTargetName ];
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

        if ! ${lib.escapeShellArgs [ zfsBin "list" "-Ho" "name" sourceCfg.fullDataset ]}; then
          printf "Dataset %s does not exists; not pruning.\n" ${lib.escapeShellArg sourceCfg.fullDataset}
          exit 0
        fi

        ${lib.escapeShellArgs [
          "prune_recursive_snaps"
          sourceCfg.fullDataset
          "syncoid_${sourceCfg.syncoidTag}"
        ]} || printf "Failed to prune dataset: %s\n" ${lib.escapeShellArg sourceCfg.fullDataset}
      '';
    };

    mkUser = sourceCfg: lib.mkIf (sourceCfg.user == "sync-${sourceCfg.name}") {
      isSystemUser = true;
      useDefaultShell = true;
      group = sourceCfg.user;
      openssh.authorizedKeys.keys = lib.mkIf (sourceCfg.sshKey != null) [ sourceCfg.sshKey ];
      
      # syncoid wants these packages
      packages = [
        pkgs.mbuffer
        pkgs.lzop
      ];
    };

    mkGroup = sourceCfg: lib.mkIf (sourceCfg.user == "sync-${sourceCfg.name}") {};
  in
  lib.mkIf cfg.target.enable {
    systemd.targets = {
      "${destTargetBaseName}" = destTarget;
    };

    systemd.services = lib.mkMerge (map (sourceCfg: {
      "sync-create-${sourceCfg.name}" = mkCreateDatasetService sourceCfg;
      "sync-perms-${sourceCfg.name}" = mkAcceptPermsService sourceCfg;
      "sync-prune-${sourceCfg.name}" = mkPruneSyncSnapsService sourceCfg;
    }) (lib.attrValues cfg.target.acceptSources));

    users.users = lib.mkMerge (map (sourceCfg: {
      "${sourceCfg.user}" = mkUser sourceCfg;
    }) (lib.attrValues cfg.target.acceptSources));

    users.groups = lib.mkMerge (map (sourceCfg: {
      "${sourceCfg.user}" = mkGroup sourceCfg;
    }) (lib.attrValues cfg.target.acceptSources));
  };
}
