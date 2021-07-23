{ config, pkgs, ... }:

{
  imports = [
    ./root.nix
    ./boot.nix
    ./home.nix
    ./persist.nix
    ./swap.nix
  ];

  options = {
  };

  config = {
  };
}
