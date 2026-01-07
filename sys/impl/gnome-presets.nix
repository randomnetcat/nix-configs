{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.services.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
  };
}
