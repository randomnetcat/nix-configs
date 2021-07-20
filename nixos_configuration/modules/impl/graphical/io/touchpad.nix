{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    # Enable touchpad support (enabled default in most desktopManager).
    services.xserver.libinput.enable = true;
  };
}
