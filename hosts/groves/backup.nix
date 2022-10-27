{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    services.duplicati = {
      enable = true;
      user = "root";
    };


    users.users.duplicati = {
      isSystemUser = true;
      uid = config.ids.uids.duplicati;
      home = "/var/lib/duplicati";
      createHome = true;
      group = "duplicati";
    };

    services.syncoid = {
      enable = true;

      commonArgs = [ "--no-privilege-elevation" "--no-sync-snap" "--keep-sync-snap" "--no-rollback" ];

      commands."zfs-rent-user" = {
        target = "sync-groves@randomcat.zfs.rent:nas_1758665d/safe/rpool_fxooop_bak/groves/user";
        source = "rpool_fxooop/groves/user";
        recursive = true;
        sshKey = "/var/lib/syncoid/id_ed25519_zfs_rent";
      };

      commands."zfs-rent-system" = {
        target = "sync-groves@randomcat.zfs.rent:nas_1758665d/safe/rpool_fxooop_bak/groves/system";
        source = "rpool_fxooop/groves/system";
        recursive = true;
        sshKey = "/var/lib/syncoid/id_ed25519_zfs_rent";
      };
    };
  };
}
