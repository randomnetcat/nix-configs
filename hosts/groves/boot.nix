{ pkgs, lib, ... }:

{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    fileSystems."/efi" = {
      device = "/dev/disk/by-partlabel/groves_ESP";
      fsType = "vfat";
    };

    boot.loader.efi.efiSysMountPoint = "/efi";

    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/groves_nixos_boot";
      fsType = "ext4";
    };
  };
}
