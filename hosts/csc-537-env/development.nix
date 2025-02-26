{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = {
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    environment.systemPackages = [ pkgs.man-pages pkgs.man-pages-posix ];
    documentation.dev.enable = true;
  };
}
