{ config, lib, pkgs, ... }:

{
  imports = [
    ./external.nix
    ./network-target.nix
    ./prune.nix
    ./snapshots.nix
  ];
}
