{ config, pkgs, ... }:

{
  config = {
    boot.initrd.supportedFilesystems = [ "zfs" ];
    boot.supportedFilesystems = [ "zfs" ];

    boot.kernelParams = [ "nohibernate" ]; # Cannot hibernate with ZFS or random encryption swap

    fileSystems =
      let
        zfsMount = fs: {
          device = "rpool_wbembv/shaw/" + fs;
          fsType = "zfs";
          options = [ "zfsutil" ];
        };
      in
      {
        "/" = zfsMount "system/root";
        "/nix" = zfsMount "local/nix";
      };

    swapDevices = [
      {
        device = "/dev/disk/by-partlabel/shaw_swap_1";
        randomEncryption.enable = true;
      }
    ];
  };
}
