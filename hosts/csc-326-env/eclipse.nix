{ pkgs, lib, config, ... }:

{
  config = {
    environment.systemPackages = [
      (pkgs.eclipses.override { jdk = pkgs.openjdk17; }).eclipse-jee
    ];

    environment.etc."jdks/11".source= pkgs.openjdk11.home;
    environment.etc."jdks/17".source= pkgs.openjdk17.home;
  };
}
