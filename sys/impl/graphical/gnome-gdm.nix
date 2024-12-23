{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  options = { };

  config = {
    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # Temporary work around for NVidia driver issue.
    # See https://gitlab.freedesktop.org/mesa/mesa/-/issues/11723#note_2538776
    environment.variables = {
      GSK_RENDERER = "gl";
    };
  };
}
