{ pkgs, lib, ... }:

{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    boot.loader.systemd-boot.editor = false;

    fileSystems."/efi" = {
      device = "/dev/disk/by-partlabel/groves_ESP";
      fsType = "vfat";
    };

    boot.loader.efi.efiSysMountPoint = "/efi";
  };
}
