{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.strawberry
    pkgs.makemkv
    pkgs.helvum
    pkgs.jellyfin-media-player
    pkgs.vlc
  ];
}
