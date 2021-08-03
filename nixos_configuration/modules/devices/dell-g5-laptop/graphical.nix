{ config, pkgs, ... }:

let
  impl-modules = ../../impl;
in
{
  imports = [
    (impl-modules + "/graphical/gnome-gdm.nix")
    (impl-modules + "/graphical/io/sound.nix")
    (impl-modules + "/graphical/io/touchpad.nix")
  ];

  options = {
  };

  config = {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia.prime = {
      offload.enable = true;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    hardware.nvidia.modesetting.enable = true;
    hardware.nvidia.nvidiaPersistenced = true;
  };
}
