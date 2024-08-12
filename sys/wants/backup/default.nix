{ config, lib, pkgs, ... }:

{
  imports = [ 
    ./source.nix
    ./target.nix
    ./network.nix
  ];
}
