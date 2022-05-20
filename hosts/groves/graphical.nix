{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/impl/graphical/gnome-gdm.nix
    ../../modules/impl/graphical/io/sound.nix
    ../../modules/impl/graphical/io/touchpad.nix
  ];

  options = {
  };
}
