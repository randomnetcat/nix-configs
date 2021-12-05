{ config, pkgs, ... }:

{
  imports = [
    ./users
    ./builders
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
