{ config, lib, pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.discord
      pkgs.slack
      pkgs.thunderbird
      pkgs.zoom-us
    ];
  };
}
