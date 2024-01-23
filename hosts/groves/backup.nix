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

      datasets."rpool_fxooop/groves/safe" = {
        useTemplate = [ "safe" ];
        recursive = "zfs";
      };
    };

    services.syncoid = {
      enable = true;

      commonArgs = [ "--no-privilege-elevation" ];
      localSourceAllow = [ "bookmark" "hold" "send" "snapshot" "destroy" "mount" ];

      # Run every day at 16:00 UTC.
      interval = "*-*-* 16:00:00";
    };
  };
}
