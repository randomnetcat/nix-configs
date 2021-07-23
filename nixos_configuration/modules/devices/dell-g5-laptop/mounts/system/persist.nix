{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    fileSystems."/persist" = {
      device = "/dev/mapper/vg_rcat-nixos_persist";
      fsType = "ext4";
    };
  };
}
