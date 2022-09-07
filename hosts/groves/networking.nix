{ config, pkgs, ... }:

{
  imports = [
    ../../modules/impl/networking/wifi.nix
  ];

  options = {
  };

  config = {
    # Let NetworkManager handle DHCP
    networking.useDHCP = false;
    networking.interfaces.enp46s0.useDHCP = false;
    networking.interfaces.wlp0s20f3.useDHCP = false;

    environment.systemPackages = [
      pkgs.networkmanagerapplet
      pkgs.networkmanager-openvpn
      pkgs.networkmanager-openconnect
    ];
  };
}
