{ config, lib, pkgs, ... }:

{
  config = {
    environment.systemPackages = [
      pkgs.linux-manual
      pkgs.man-pages
      pkgs.man-pages-posix
    ];

    documentation.man.enable = true;
    documentation.dev.enable = true;
  };
}
