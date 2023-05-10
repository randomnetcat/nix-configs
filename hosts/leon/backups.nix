{ config, pkgs, lib, inputs, ... }:

{
  config = {
    environment.systemPackages = [
      pkgs.mbuffer
      pkgs.pv
      pkgs.zstd
    ];

    nixpkgs.overlays = [
      (final: prev: {
        sanoid = prev.sanoid.overrideAttrs (oldAttrs: {
          src = "${inputs.patched-sanoid}";
        });
      })
    ];

    services.sanoid = {
      enable = true;
      extraArgs = [ "--verbose" "--debug" ];

      templates."backup" = {
        yearly = 999999;
        monthly = 999999;
        daily = 999999;
        hourly = 0;
        autosnap = false;
        autoprune = true;
      };

      datasets."nas_1758665d/safe/rpool_sggau1_bak" = {
        useTemplate = [ "backup" ];
        recursive = "zfs";
      };
    };

    services.syncoid = {
      enable = true;
 
      interval = "*-*-* 11:00:00";
 
      commonArgs = [
        "--no-privilege-elevation"
        "--no-rollback"
        "--no-sync-snap"
        "--create-bookmark"
        "--debug"
      ];

      localTargetAllow = [
        "create"
        "mountpoint"
        "mount"
        "receive"

        # I'm not thrilled about having to grant this permission.
        # However, it appears necessary for ZFS to allow removing any incomplete sync
        # state, which sometimes has to happen.
        #
        # As best I can tell, syncoid does not destroy anything other than sync snapshots
        # unless it is explicitly asked to, so this *should* be fine.
        #
        # I'm going to live to regret this, aren't I?
        "destroy"
      ];
 
      commands."reese-system" = {
        target = "nas_1758665d/safe/rpool_sggau1_bak/reese/system";
        source = "backup@reese:rpool_sggau1/reese/system";
        recursive = true;

        extraArgs = [
          "--compress=zstd-fast"
        ];
      };
    };

    systemd.services =
      let
        commonConfig = {
          unitConfig = {
            StartLimitBurst = 5;
            StartLimitIntervalSec = "12 hours";
          };

          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "10min";
            TimeoutStartSec = "2 hours";
          };
        };
      in {
        syncoid-reese-system = commonConfig;
      };
  };
}
