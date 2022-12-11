{ config, lib, pkgs, ... }:

{
  imports = [
    ./general-development.nix
  ];

  options = {
  };

  config = {
    home.file."dev/jdks/current".source = pkgs.jdk.home;
    home.file."dev/jdks/17".source = pkgs.jdk17.home;
    home.file."dev/jdks/11".source = pkgs.jdk11.home;

    programs.java.enable = true;
    programs.java.package = pkgs.jdk;

    home.packages = [
      pkgs.jetbrains.idea-ultimate
      pkgs.gradle
      pkgs.jd-gui
    ];
  };
}
