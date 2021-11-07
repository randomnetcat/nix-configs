{ config, lib, pkgs, nixopsPkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    home.packages = [ nixopsPkgs.nixops ];
  };
}
