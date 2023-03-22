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
