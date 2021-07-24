{ config, pkgs, ... }:

{
  imports = [
    ./users
  ];

  options = {
  };

  config = {
    nixpkgs.config.allowUnfree = true;
    nix.autoOptimiseStore = true;

    environment.systemPackages = [
      pkgs.nano
      pkgs.git
    ];
  };
}
