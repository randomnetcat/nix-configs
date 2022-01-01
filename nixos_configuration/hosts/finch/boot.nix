{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/impl/boot/systemd-boot.nix
  ];

  config = {
    randomcat.system.efi.espDevice = "/dev/disk/by-uuid/A0A9-C254";
    boot.loader.efi.canTouchEfiVariables = true;

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/nixos_boot";
      fsType = "ext4";
    };
  };
}
