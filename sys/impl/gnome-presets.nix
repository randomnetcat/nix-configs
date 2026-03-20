{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.services.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
    programs.gnome-terminal.enable = true;

    environment.gnome.excludePackages = [
      pkgs.gnome-console
    ];
  };
}
