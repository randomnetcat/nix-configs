{ pkgs, lib, ... }:

{
  config = {
    home.packages = [
      pkgs.networkmanager-openconnect
    ];
  };
}
