{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    fileSystems."/" = {
      device = "/dev/mapper/vg_rcat-nixos_root";
      fsType = "ext4";
    };

    fileSystems."/nix" = {
      device = "/dev/mapper/vg_rcat-nixos_nix_store";
      fsType = "ext4";
    };
  };
}
