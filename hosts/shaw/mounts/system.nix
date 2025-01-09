{ config, lib, pkgs, ... }:

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

    # If the initrd is systemd, we have to order the zpool import after the
    # systemd-cryptsetup service (which loads the key for the boot device).
    #
    # If we don't do this, then the zfs-import service will continue trying to
    # import it until eventually timing out. This results in the zfs-import
    # service failing and thus failing the boot (resulting in systemd loading
    # emergency.target).
    #
    # I believe that this would usually be unnecessary because systemd would
    # generate the correct block device dependencies, but ZFS doesn't import
    # from any specific block device, so that's not possible, and we have to do
    # this.
    boot.initrd.systemd.services."zfs-import-rpool_wbembv" = lib.mkIf (config.boot.initrd.systemd.enable) {
      wants = [ "systemd-cryptsetup@cryptroot.service" ];
      after = [ "systemd-cryptsetup@cryptroot.service" ];
    };

    swapDevices = [
      {
        device = "/dev/disk/by-partlabel/shaw_swap_1";
        randomEncryption.enable = true;
      }
    ];
  };
}
