{ config, pkgs, ... }:

let
  impl-modules = ../../impl;
in
{
  imports = [
    (impl-modules + "/global.nix")
    (impl-modules + "/boot/grub-efi.nix")

    ./mounts/system

    ./graphical.nix
    ./networking.nix
    ./locale.nix

    # Features
    ./gaming.nix
    ./development.nix
    ./backup.nix
  ];

  options = {
  };

  config = {
  };
}
