{ config, pkgs, ... }:

{
  imports = [
    ./root.nix
    ./boot.nix
    ./home.nix
    ./swap.nix
  ];

  options = {
  };

  config = {
  };
}
