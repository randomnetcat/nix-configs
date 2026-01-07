{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = [
      pkgs.android-tools
    ];
  };
}
