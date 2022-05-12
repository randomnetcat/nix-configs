{ config, lib, pkgs, ... }:

{
  imports = [
    ../detail/version-control-common.nix
  ];

  options = {};

  config = {
    programs.git = {
      userEmail = "jecobb2@ncsu.edu";
      userName = "Jason Cobb";
    };
  };
}
