{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.strawberry
    pkgs.makemkv
    pkgs.crosspipe
    pkgs.jellyfin-media-player
    pkgs.vlc
  ];
}
