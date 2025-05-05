{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../sys/wants/backup/default.nix
    ../../../sys/wants/backup/network.nix
    ../../../network
  ];

  config = {
    randomcat.services.backups = {
      fromNetwork = true;

      target = {
        encryptedSyncKey = ../secrets/sync-key;
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

      datasets."nas_oabrke/data/backups/groves" = {
        useTemplate = [ "safe_backup" ];
        recursive = "zfs";
      };

      datasets."nas_oabrke/data/backups/reese" = {
        useTemplate = [ "safe_backup" ];
        recursive = "zfs";
      };
    };
  };
}
