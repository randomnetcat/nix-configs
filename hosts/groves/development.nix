{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    environment.systemPackages = [
      pkgs.linux-manual
      pkgs.man-pages
      pkgs.man-pages-posix
    ];

    documentation.man.enable = true;
    documentation.man.generateCaches = true;
    documentation.dev.enable = true;
  };
}
