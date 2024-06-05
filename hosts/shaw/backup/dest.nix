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
  }]
  ++ (lib.mapAttrsToList (host: hostCfg: {
    users.users."sync-${host}" = {
      isSystemUser = true;
      useDefaultShell = true;
      group = "sync-${host}";
      openssh.authorizedKeys.keys = lib.mkIf (hostCfg ? key) [ hostCfg.key ];
    };

    users.groups."sync-${host}" = {};

    services.openssh.settings.AllowUsers = [
      "sync-${host}"
    ];
  }) sourceHosts));
}
