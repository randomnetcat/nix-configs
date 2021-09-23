{ config, pkgs, ... }:

{
  imports = [
    ./users
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
