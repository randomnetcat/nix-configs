{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    services.syncoid = {
      enable = true;

      # Run at 11am UTC daily. This time is chosen to minimize likelihood of concurrent
      # sending with groves.
      interval = "*-*-* 11:00:00";

      commonArgs = [ "--no-privilege-elevation" "--no-rollback" ];
      localSourceAllow = [ "bookmark" "hold" "send" "snapshot" "destroy" "mount" ];

      commands."zfs-rent-system" = {
        target = "sync-reese@randomcat.zfs.rent:nas_1758665d/safe/rpool_sggau1_bak/reese/system";
        source = "rpool_sggau1/reese/system";
        recursive = true;
        sshKey = "/var/lib/syncoid/syncoid-id-zfs-rent";
        extraArgs = [ "--identifier=zfs-rent" ];
      };
    };

    users.users.syncoid.extraGroups = [ "keys" ];

    randomcat.secrets.secrets."syncoid-id-zfs-rent" = {
      encryptedFile = ./secrets/syncoid-id-zfs-rent;
      dest = "/var/lib/syncoid/syncoid-id-zfs-rent";
      owner = "syncoid";
      group = "syncoid";
      permissions = "700";
    };
  };
}
