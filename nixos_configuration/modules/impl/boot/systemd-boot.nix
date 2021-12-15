{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.efiSysMountPoint = "/boot/efi";
    boot.loader.efi.canTouchEfiVariables = true;

    boot.loader.generationsDir.copyKernels = true;
  };
}
