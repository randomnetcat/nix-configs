{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/impl/graphical/gnome-gdm.nix
    ../../modules/impl/graphical/io/sound.nix
    ../../modules/impl/graphical/io/touchpad.nix
  ];

  options = {
    randomcat.hosts.finch.proprietaryGraphics.enable = lib.mkEnableOption "proprietary nvidia graphics";
  };

  config = lib.mkIf (config.randomcat.hosts.finch.proprietaryGraphics.enable) {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia.prime = {
      sync.enable = true;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    hardware.nvidia.modesetting.enable = true;
    hardware.nvidia.nvidiaPersistenced = true;

    boot.blacklistedKernelModules =  [ "nouveau" ];

    services.xserver.displayManager.sessionCommands = ''
      ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource modesetting NVIDIA-0
    '';
  };
}