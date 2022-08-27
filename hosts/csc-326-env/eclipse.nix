{ pkgs, lib, config, ... }:

{
  config = {
    environment.systemPackages = [
      pkgs.eclipses.eclipse-jee
    ];

    environment.etc."jdks/11".source= pkgs.openjdk11.home;
  };
}
