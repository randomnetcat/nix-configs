{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.services.xserver.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
  };
}
