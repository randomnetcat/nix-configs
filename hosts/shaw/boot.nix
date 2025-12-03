{ pkgs, config, lib, ... }:

{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    boot.loader.systemd-boot.editor = false;
    boot.loader.efi.efiSysMountPoint = "/boot";
  };
}
