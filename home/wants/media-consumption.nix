{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.strawberry
    pkgs.helvum
    pkgs.jellyfin-media-player
    pkgs.vlc

    # Temporarily removed due to build failure.
    # pkgs.makemkv
  ];
}
