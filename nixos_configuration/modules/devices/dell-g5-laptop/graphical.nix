{ config, pkgs, ... }:

let
  impl-modules = ../../impl;
in
{
  imports = [
    (impl-modules + "/graphical/gnome-lightdm.nix") # NVIDIA card doesn't work under GDM for... some reason
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

    hardware.nvidia.nvidiaPersistenced = true;
  };
}
