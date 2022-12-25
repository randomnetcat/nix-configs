{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.boot.zfs.enabled) {
    services.zfs.trim.enable = true;
    services.zfs.autoScrub.enable = true;
    boot.zfs.forceImportRoot = false;
  };
}
