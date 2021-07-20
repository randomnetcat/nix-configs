{ config, pkgs, ... }:

let
  impl-modules = ../../impl;
in
{
  imports = [
    (impl-modules + "/global.nix")
    (impl-modules + "/boot/grub-efi.nix")
    ./graphical.nix
    ./networking.nix
    ./gaming.nix
    ./locale.nix
    ./mounts
  ];

  options = {
  };

  config = {
  };
}
