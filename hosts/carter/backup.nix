{ config, pkgs, ... }:

{
  imports = [
    ../../network
  ];

  config = {
    services.sanoid = {
      enable = true;
      interval = "*:0/15";
      extraArgs = [ "--verbose" "--debug" ];

      settings."template_safe" = {
        weekly = 8;
        frequently = 12;
        frequent_period = 15;
      };

      templates."safe" = {
        yearly = 2;
        monthly = 24;
        daily = 14;
        hourly = 4;
        autosnap = true;
        autoprune = true;
      };

      datasets."rpool_ez8ryx/carter/safe" = {
        useTemplate = [ "safe" ];
        recursive = "zfs";
      };
    };

    systemd.timers.sanoid = {
      timerConfig.Persistent = true;
    };

    randomcat.services.backups.source = {
      fromNetwork = true;
      ssh.enable = true;
      ssh.enableVpnAddresses = true;
    };
  };
}
