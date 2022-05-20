{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/impl/boot/systemd-boot.nix
  ];

  config = {
    randomcat.system.efi.espDevice = "/dev/disk/by-partlabel/groves_ESP";
    boot.loader.efi.canTouchEfiVariables = true;

    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/groves_nixos_boot";
      fsType = "ext4";
    };
  };
}
