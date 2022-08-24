{ pkgs, lib, config, ... }:

{
  config = {
    environment.systemPackages = [
      pkgs.eclipses.eclipse-java
    ];

    environment.etc."jdks/17".source= pkgs.openjdk17.home;
  };
}
