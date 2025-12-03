{ config, lib, pkgs, ... }:

let
  targetPath = "/mnt/birdhouse/restic/repo";

  extraBackupPaths = [
    "/srv/archive/internet"
    "/srv/archive/media/bluray"
    "/srv/archive/media/dvd"
    "/srv/archive/ncsu-google"
    "/srv/archive/nebula"
    "/srv/archive/nomic"
  ];
in
{
  config = {
    users.users.restic = {
      isSystemUser = true;
      group = "restic";
    };

    users.groups.restic = {};

    systemd.services.backup-restic-birdhouse = {
      serviceConfig = {
        PrivateTmp = true;
        PrivateMounts = true;
        PrivateNetwork = true;
        NoNewPrivileges = true;
        UMask = "0077";

        # Required for listing datasets.
        DeviceAllow = "/dev/zfs";
        DevicePolicy = "closed";

        TemporaryFileSystem = "/mnt";
        BindPaths = "${targetPath}:/mnt/restic-repo";
        StateDirectory = "backup-restic/birdhouse";
        StateDirectoryMode = "0700";

        LoadCredentialEncrypted = [
          "birdhouse-restic-password:${../secrets/birdhouse-restic-password}"
        ];
      };

      unitConfig = {
        AssertPathIsDirectory = targetPath;
        RequiresMountsFor = targetPath;
      };

      enableStrictShellChecks = true;

      path = [
        pkgs.util-linux
        pkgs.getent
        pkgs.restic
      ];

      script = ''
        set -eu -o pipefail

        restic_uid="$(getent -- passwd ${lib.escapeShellArg config.users.users.restic.name} | cut -d: -f3)"
        restic_gid="$(getent -- group ${lib.escapeShellArg config.users.groups.restic.name} | cut -d: -f3)"

        restic_owns() {
          local target="$1"

          local current_owners
          current_owners="$(stat -c '%u %g' -- "$target")"

          if [[ "$current_owners" != "$restic_uid $restic_gid" ]]; then
            chown "$restic_uid:$restic_gid" -R -- "$target"
            chmod -x,u=rwX,go= -R -- "$target"
          fi
        }

        export HOME="$STATE_DIRECTORY/home"
        mkdir -p -- "$HOME"
        restic_owns "$HOME"
        cd -- "$HOME"

        repo="/mnt/restic-repo"
        restic_owns "$repo"

        # Modelled after syncoid & sanoid modules. Use the booted ZFS in order to guarantee stability.
        zfs="/run/booted-system/sw/bin/zfs"

        backups_dir="/mnt/backups"
        base_dataset="nas_oabrke/data/backups"

        mkdir -m 0700 -- "$backups_dir"

        "$zfs" list -t filesystem -H -o name -r -- "$base_dataset" | while IFS="" read -r fs; do
            echo "Filesystem: $fs" 2>&1

            if [[ "$fs" = "$base_dataset" ]]; then
                echo "Base dataset: skipping." >&2
                continue
            fi

            if ! [[ "$fs" = "$base_dataset/"* ]]; then
                echo "Invalid filesystem: $fs" >&2
                exit 1
            fi

            suffix="${"$"}{fs#"$base_dataset/"}"
            echo "Suffix: $suffix" >&2

            fs_mountpoint="$("$zfs" get -H mountpoint -o value -- "$fs")"

            if [[ "$fs_mountpoint" != "legacy" ]]; then
                echo "Invalid ZFS mountpoint: $fs_mountpoint" >&2
                exit 1
            fi

            mount_str="${"$"}{suffix//"/"/"-"}"
            echo "Mount string: $mount_str" >&2

            mkdir -- "$backups_dir/$mount_str"
            mount -t zfs -o ro,nodev,nosuid -- "$fs" "$backups_dir/$mount_str"
        done

        RESTIC_PASSWORD="$(cat -- "$CREDENTIALS_DIRECTORY/birdhouse-restic-password")"
        export RESTIC_PASSWORD

        exec setpriv ${lib.cli.toGNUCommandLineShell {} {
          reuid = config.users.users.restic.name;
          regid = config.users.groups.restic.name;
          inh-caps = "-all,+dac_read_search";
          ambient-caps = "-all,+dac_read_search";
          clear-groups = true;
          no-new-privs = true;
        }} -- restic --repo "$repo" backup --json -- "$backups_dir" ${lib.escapeShellArgs extraBackupPaths}
      '';
    };
  };
}
