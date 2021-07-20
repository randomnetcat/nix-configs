{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;
  };
}
