{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    fileSystems."/home" = {
      device = "/dev/mapper/vg_rcat-nixos_home";
      fsType = "ext4";
    };
  };
}
