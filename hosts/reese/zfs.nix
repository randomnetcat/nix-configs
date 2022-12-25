{ config, pkgs, inputs, ... }:

{
  config = {
    services.zfs.expandOnBoot = [ "rpool_sggau1" ];

    services.sanoid = {
      enable = true;

      extraArgs = [ "--verbose" ];

      templates."safe" = {
        yearly = 0;
        monthly = 0;
        daily = 7;
        hourly = 24;
        autosnap = true;
        autoprune = true;
      };

      datasets."rpool_sggau1/reese/system" = {
        useTemplate = [ "safe" ];
        recursive = "zfs";
      };
    };
  };
}
