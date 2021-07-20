{ config, pkgs, ... }:

let
  impl-modules = ../../impl;
in
{
  imports = [
    (impl-modules + "/graphical/gnome.nix")
    (impl-modules + "/graphical/io/sound.nix")
    (impl-modules + "/graphical/io/touchpad.nix")
  ];

  options = {
  };

  config = {
  };
}
