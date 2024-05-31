{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.boot.zfs.enabled) {
    services.zfs.trim.enable = true;
    boot.zfs.forceImportRoot = false;

    services.zfs.autoScrub = {
      enable = true;
      interval = "Sun, 02:00";
    };
  };
}
