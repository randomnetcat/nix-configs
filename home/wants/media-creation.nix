{ config, lib, pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.gimp
      pkgs.audacity
      pkgs.libreoffice
      pkgs.corefonts
      pkgs.inkscape
    ];

    programs.obs-studio.enable = true;
    fonts.fontconfig.enable = true;
  };
}
