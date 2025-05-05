{ config, lib, pkgs, ... }:

{
  imports = [
    ./network.nix
    ./prune.nix
    ./source.nix
    ./source-ssh.nix
    ./target.nix
  ];
}
