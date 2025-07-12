{ config, pkgs, ... }:

{
  imports = [
    ../../sys/impl/networking/wifi.nix
  ];

  config = {
    # Let NetworkManager handle DHCP
    networking.useDHCP = false;
    networking.interfaces.enp46s0.useDHCP = false;
    networking.interfaces.wlp0s20f3.useDHCP = false;

    systemd.network.enable = false;

    networking.networkmanager = {
      enable = true;
    };
  };
}
