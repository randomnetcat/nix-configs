{ config, pkgs, ... }:

{
  imports = [
    ./efi-common
  ];

  config = {
    randomcat.system.efi.enable = true;
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;
  };
}
