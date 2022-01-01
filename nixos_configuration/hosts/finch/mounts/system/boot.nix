{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {    
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/nixos_boot";
      fsType = "ext4";
    };

    fileSystems."/boot/efi" = {
      device = "/dev/disk/by-uuid/A0A9-C254";
      fsType = "vfat";
    };
  };
}
