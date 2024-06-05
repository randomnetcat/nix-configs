{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

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

      datasets."rpool_fxooop/groves/safe" = {
        useTemplate = [ "safe" ];
        recursive = "zfs";
      };
    };

    services.syncoid = {
      enable = true;

      commonArgs = [ "--no-privilege-elevation" "--keep-sync-snap" ];
      localSourceAllow = [ "bookmark" "hold" "send" "snapshot" "destroy" "mount" ];

      # Run every day at 16:00 UTC.
      interval = "*-*-* 16:00:00";

      commands."shaw" = {
        target = "sync-groves@shaw:nas_oabrke/data/backups/groves";
        source = "rpool_fxooop/groves/safe";
        recursive = true;
        sshKey = "/var/lib/syncoid/id_ed25519_zfs_rent";
      };
    };

    systemd.timers =
      let
        commonConfig = {
          Persistent = true;
        };
      in {
        syncoid-shaw.timerConfig = commonConfig;
      };

    systemd.services =
      let
        commonConfig = {
          unitConfig = {
            StartLimitBurst = 3;
            StartLimitIntervalSec = "12 hours";
          };

          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "15min";
            TimeoutStartSec = "2 hours";
          };
        };
      in {
        syncoid-shaw = commonConfig;
      };
  };
}
