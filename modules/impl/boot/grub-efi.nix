{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    boot.loader.systemd-boot.enable = false;
    boot.loader.grub.enable = true;

    boot.loader.grub.version = 2;

    boot.loader.efi.efiSysMountPoint = "/boot/efi";
    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.loader.generationsDir.copyKernels = true;
  };
}
