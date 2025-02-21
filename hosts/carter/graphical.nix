{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sys/impl/graphical/gnome-gdm.nix
  ];

  config = {
    services.xserver.videoDrivers = [ "amd" ];
    hardware.graphics.enable = true;
  };
}
