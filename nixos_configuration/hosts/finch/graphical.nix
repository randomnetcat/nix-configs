{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/impl/graphical/gnome-gdm.nix
    ../../modules/impl/graphical/io/sound.nix
    ../../modules/impl/graphical/io/touchpad.nix
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

    boot.blacklistedKernelModules =  [ "nouveau" ];

    services.xserver.displayManager.sessionCommands = ''
      ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource NVIDIA-G0 modesetting
  '';
  };
}
