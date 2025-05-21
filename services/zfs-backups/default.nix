{ config, lib, pkgs, ... }:

{
  imports = [
    ./metrics.nix
    ./network.nix
    ./prune.nix
    ./source.nix
    ./target.nix
  ];
}
