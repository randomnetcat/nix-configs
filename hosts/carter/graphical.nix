{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sys/impl/graphical/gnome-gdm.nix
  ];

  config = {
    services.xserver.videoDrivers = [ "amd" ];
    boot.initrd.kernelModules = [ "amdgpu" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
