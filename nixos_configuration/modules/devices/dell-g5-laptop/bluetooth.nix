{ config, pkgs, ... }:

{
  config = {
    # This makes blutetooth audio work
    # From https://nixos.wiki/wiki/Bluetooth

    hardware.pulseaudio.enable = true;
    hardware.bluetooth.enable = true;

    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
}
