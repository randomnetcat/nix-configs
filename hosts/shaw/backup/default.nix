{ config, lib, pkgs, ... }:

{
  imports = [
    ./network-target.nix
    ./prune.nix

    ./external.nix
  ];
}
