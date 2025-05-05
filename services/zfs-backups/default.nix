{ config, lib, pkgs, ... }:

{
  imports = [
    ./metrics.nix
    ./network.nix
    ./prune.nix
    ./source.nix
    ./source-ssh.nix
    ./target.nix
  ];
}
