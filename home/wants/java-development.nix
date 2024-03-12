{ config, lib, pkgs, ... }:

{
  imports = [
    ./general-development.nix
  ];

  options = {
  };

  config =
    let
      currentJDK = pkgs.jdk21;
    in
    {
      home.file."dev/jdks/current".source = currentJDK.home;
      home.file."dev/jdks/17".source = pkgs.jdk17.home;
      home.file."dev/jdks/11".source = pkgs.jdk11.home;

      programs.java.enable = true;
      programs.java.package = pkgs.jdk;

      home.packages = [
        pkgs.jetbrains.idea-ultimate
        (pkgs.gradle.override {
          javaToolchains = [
            pkgs.jdk11.home
            pkgs.jdk17.home
            currentJDK.home
          ];
        })
        pkgs.jd-gui
      ];
    };
}
