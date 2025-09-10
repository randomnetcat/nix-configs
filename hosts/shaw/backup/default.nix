{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../network
  ];

  config = {
    randomcat.services.backups = {
      fromNetwork = true;

      target = {
        encryptedSyncKey = ../secrets/sync-key;
        enableLegacyMountPoint = true;
        enableMetrics = true;
      };
    };

    services.sanoid = {
      enable = true;
      interval = "*:0/15";
      extraArgs = [ "--verbose" "--debug" ];

      templates."safe_backup" = {
        yearly = 999999;
        monthly = 999999;
        weekly = 999999;
        daily = 999999;
        hourly = 0;

        autosnap = false;
        autoprune = true;
      };

      datasets."nas_oabrke/data/backups" = {
        useTemplate = [ "safe_backup" ];
        recursive = "zfs";
      };
    };
  };
}
