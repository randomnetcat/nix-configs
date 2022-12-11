{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    # Enable touchpad support (enabled default in most desktopManager).
    services.xserver.libinput.enable = true;

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hardware.pulseaudio.enable = false;
  };
}
