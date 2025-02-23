{ config, pkgs, ... }:

{
  imports = [
    ../../sys/impl/networking/wifi.nix
  ];

  options = { };

  config = {
    # Let NetworkManager handle DHCP
    networking.useDHCP = false;
  };
}
