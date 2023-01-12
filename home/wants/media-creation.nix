{ config, lib, pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.gimp
      pkgs.audacity
      pkgs.libreoffice
      pkgs.corefonts
    ];

    programs.obs-studio.enable = true;
    fonts.fontconfig.enable = true;
  };
}
