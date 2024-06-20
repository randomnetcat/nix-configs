{ config, lib, pkgs, ... }:

let
  sourceHosts = {
    reese = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkOFn/HmrUFe3/I8JI4tsRRmTtsjmSjMYruVaxrzmoV root@reese";
    };

    groves = {
      # Uses Tailscale SSH for the moment.
    };
  };

  dataPool = "nas_oabrke";
  backupsDataset = "${dataPool}/data/backups";
  zfsBin = lib.getExe' config.boot.zfs.package "zfs";

  childPerms = "create,mount,bookmark,hold,receive,snapshot";
in
{
  config = lib.mkMerge ([{
    systemd.services."zfs-backup-perms" = {
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Allow users that create datasets within the backups dataset to receive data to them
        # (including creating sub-datasets and receiving snapshots).
        echo "Setting global permissions."
        ${lib.escapeShellArgs [
          zfsBin
          "allow"
          "-c"
          childPerms
          backupsDataset
        ]}

        echo "Set global permissions."

        ${lib.concatLines (lib.mapAttrsToList (host: hostCfg: ''
          echo "Setting permissions for host:" ${lib.escapeShellArg host}
          ${pkgs.writeShellScript "zfs-backup-perms-${host}" ''
            set -eu

            # Allow sync-{host} user to create new datasets within the backups dataset.
            ${lib.escapeShellArgs [
              zfsBin
              "allow"
              "-l"
              "-u"
              "sync-${host}"
              "create,mount"
              backupsDataset
            ]}

            ${lib.escapeShellArgs [
              zfsBin
              "allow"
              "-u"
              "sync-${host}"
              childPerms
              "${backupsDataset}/${host}"
            ]} || printf "Could not grant permissions on existing dataset for host %s; ignoring.\n" ${lib.escapeShellArg host}
          ''} || echo "Failed to set permissions for host:" ${lib.escapeShellArg host}
        '') sourceHosts)}
      '';

      postStop = ''
        echo "Resetting global permissions."

        ${lib.escapeShellArgs [
          zfsBin
          "unallow"
          "-c"
          backupsDataset
        ]}

        ${lib.concatLines (lib.mapAttrsToList (host: hostCfg: ''
          echo "Resetting permissions for host:" ${lib.escapeShellArg host}
          ${pkgs.writeShellScript "zfs-reset-backup-perms-${host}" ''
            set -eu

            # Allow sync-{host} user to create new datasets within the backups dataset.
            ${lib.escapeShellArgs [
              zfsBin
              "unallow"
              "-l"
              "-u"
              "sync-${host}"
              backupsDataset
            ]}

            ${lib.escapeShellArgs [
              zfsBin
              "unallow"
              "-u"
              "sync-${host}"
              "${backupsDataset}/${host}"
            ]} || printf "Could not grant permissions on existing dataset for host %s; ignoring.\n" ${lib.escapeShellArg host}
          ''} || echo "Failed to reset backup permissions for host:" ${lib.escapeShellArg host}
        '') sourceHosts)}
      '';
    };

    systemd.services."sync-prune-snapshots" = {
      wantedBy = [ "multi-user.target" ];
      startAt = "06:00";

      serviceConfig = {
        Type = "oneshot";        
      };

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
            declare -r prefix="$2"

            echo "Pruning recursively from: $parent" >&2

            ${zfsBin} list -t filesystem -rHo name -- "$parent" | {
                while IFS="" read -r dataset; do
                    if [[ "$dataset" != "$dataset"* ]]; then
                        echo "Refusing to prune dataset: $dataset"
                        exit 1
                    fi

                    prune_dataset_snaps "$dataset" "$prefix"
                done
            }
        }

        ${lib.concatLines (lib.mapAttrsToList (host: hostCfg: ''
          ${lib.escapeShellArgs [
            "prune_recursive_snaps"
            "${backupsDataset}/${host}"
            "syncoid_${host}"
          ]} || printf "Failed to prune dataset: %s\n" ${lib.escapeShellArg "${backupsDataset}/${host}"}
        '') sourceHosts)}
      '';
    };
  }]
  ++ (lib.mapAttrsToList (host: hostCfg: {
    users.users."sync-${host}" = {
      isSystemUser = true;
      useDefaultShell = true;
      group = "sync-${host}";
      openssh.authorizedKeys.keys = lib.mkIf (hostCfg ? key) [ hostCfg.key ];
      
      # syncoid wants these packages
      packages = [
        pkgs.mbuffer
        pkgs.lzop
      ];
    };

    users.groups."sync-${host}" = {};

    services.openssh.settings.AllowUsers = [
      "sync-${host}"
    ];
  }) sourceHosts));
}
