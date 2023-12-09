{ config, pkgs, ... }:

{
  config = {
    boot.initrd.supportedFilesystems = [ "zfs" ];
    boot.supportedFilesystems = [ "zfs" ];

    boot.kernelParams = [ "nohibernate" ]; # Cannot hibernate with ZFS or random encryption swap

    boot.initrd.luks.devices = {
      "cryptroot" = {
        device = "/dev/disk/by-partuuid/996f43f1-1fba-4e42-acd8-e5a17b110311";
        preLVM = true;
      };
    };

    fileSystems =
      let
        zfsMount = fs: {
          device = "rpool_wbembv/shaw/" + fs;
          fsType = "zfs";
          options = [ "zfsutil" ];
        };
      in
      {
        "/boot" = {
          device = "/dev/disk/by-partuuid/d6a4624b-d26d-4ad3-9400-89f23f8faf64";
          fsType = "vfat";

          options = [
            "uid=0"
            "gid=0"
            "umask=077"
          ];
        };

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
