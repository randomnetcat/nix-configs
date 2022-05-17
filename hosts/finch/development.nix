{ config, pkgs, ... }:

{
  imports = [
    ./mounts/feature/projects.nix
    ../../modules/wants/android-development
  ];

  options = {
  };

  config = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    environment.systemPackages = [ pkgs.man-pages pkgs.man-pages-posix ];
    documentation.dev.enable = true;

    users.users.randomcat.extraGroups = [ "adbusers" ];
  };
}
