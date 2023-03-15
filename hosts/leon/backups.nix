{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = [
      pkgs.mbuffer
      pkgs.pv
      pkgs.zstd
    ];

    services.syncoid = {
      enable = true;
 
      interval = "*-*-* 11:00:00";
 
      commonArgs = [
        "--no-privilege-elevation"
        "--no-rollback"
        "--no-sync-snap"
        "--create-bookmark"
      ];

      localTargetAllow = [
        "create"
        "mountpoint"
        "mount"
        "receive"
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
  };
}
