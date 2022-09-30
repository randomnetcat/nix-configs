{ config, pkgs, ... }:

{
  imports = [
    ./users
    ./builders
    ./maintenance
  ];

  options = {
  };

  config = {
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = [
      pkgs.nano
      pkgs.git
    ];
  };
}
