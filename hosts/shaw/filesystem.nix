{ config, lib, pkgs, ... }:

{
  config = {
    services.zfs.autoScrub.enable = true;
    services.zfs.trim.enable = true;

    boot.supportedFilesystems = {
      ext4 = true;
    };
  };
}
