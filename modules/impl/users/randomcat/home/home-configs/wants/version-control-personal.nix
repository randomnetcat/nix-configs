{ config, lib, pkgs, ... }:

{
  imports = [
    ../detail/version-control-common.nix
  ];

  options = {};

  config = {
    programs.git = {
      userEmail = "jason.e.cobb@gmail.com";
      userName = "Jason Cobb";
    };
  };
}
