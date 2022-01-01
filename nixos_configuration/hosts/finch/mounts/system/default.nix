{ config, pkgs, ... }:

{
  imports = [
    ./root.nix
    ./home.nix
    ./swap.nix
  ];

  options = {
  };

  config = {
  };
}
