{ config, lib, pkgs, ... }:

{
  imports = [
    ./sanoid-defaults.nix
  ];

  config = {
    services.sanoid = {
      templates."safe_local" = {
        yearly = 1;
        monthly = 24;
        weekly = 8;
        daily = 14;
        hourly = 48;

        autosnap = true;
        autoprune = true;
      };

      settings."template_safe_local" = {
        frequently = 12;
        frequent_period = 15;
      };

      datasets."nas_oabrke/data/archive" = {
        useTemplate = [ "safe_local" ];
        recursive = "zfs";
      };

      datasets."nas_oabrke/data/users" = {
        useTemplate = [ "safe_local" ];
        recursive = "zfs";
      };

      datasets."rpool_wbembv/shaw/system" = {
        useTemplate = [ "safe_local" ];
        recursive = "zfs";
      };
    };
  };
}
