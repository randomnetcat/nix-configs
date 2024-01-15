{ pkgs, lib, ... }:

{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    boot.loader.systemd-boot.editor = false;

    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/groves-esp";
      fsType = "vfat";

      options = [
        "uid=0"
        "gid=0"
        "umask=077"
      ];
    };

    boot.loader.efi.efiSysMountPoint = "/boot";
  };
}
