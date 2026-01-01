{ config, pkgs, ... }:

{
  imports = [
    ../../sys/impl/networking/wifi.nix
  ];

  config = {
    # Let NetworkManager handle DHCP
    networking.useDHCP = false;

    environment.systemPackages = [
      pkgs.wireguard-tools
    ];
  };
}
