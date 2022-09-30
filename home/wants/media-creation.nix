{ config, lib, pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.gimp
      pkgs.audacity
      pkgs.libreoffice
    ];

    programs.obs-studio.enable = true;
  };
}
