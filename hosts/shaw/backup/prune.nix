{ config, lib, pkgs, ... }:

{
  imports = [
    ./sanoid-defaults.nix
  ];

  config = {
    services.sanoid = {
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
