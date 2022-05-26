{ config, lib, pkgs, ... }:

{
  config = {
    services.zfs.autoScrub.enable = true;
    services.zfs.trim.enable = true;

    services.zfs.autoSnapshot.enable = true;
    services.zfs.autoSnapshot.frequent = 12;
    services.zfs.autoSnapshot.daily = 14;
    services.zfs.autoSnapshot.weekly = 8;
    services.zfs.autoSnapshot.monthly = 24;
  };
}
