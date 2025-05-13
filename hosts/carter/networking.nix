{ config, pkgs, ... }:

{
  imports = [
    ../../sys/impl/networking/wifi.nix
  ];

  options = { };

  config = {
    # Let NetworkManager handle DHCP
    networking.useDHCP = false;

    systemd.network = {
      # Needed for birdsong wireguard.
      enable = true;

      # Internet connectivity is managed by NetworkManager.
      wait-online.enable = false;
    };
  };
}
