{ config, pkgs, inputs, ... }:

{
  config = {
    services.sanoid = {
      enable = true;

      extraArgs = [ "--verbose" ];

      templates."safe" = {
        yearly = 4;
        monthly = 12;
        daily = 28;
        hourly = 48;
        autosnap = true;
        autoprune = true;
      };

      datasets."rpool_sggau1/reese" = {
        useTemplate = [ "safe" ];
        recursive = "zfs";
      };
    };
  };
}
