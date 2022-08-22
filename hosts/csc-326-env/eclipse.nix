{ pkgs, lib, config, ... }:

{
  config = {
    environment.systemPackages = [
      pkgs.eclipses.eclipse-jee
    ];
  };
}
