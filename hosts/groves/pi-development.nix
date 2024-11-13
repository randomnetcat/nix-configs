{ config, pkgs, lib, ... }:

{
  config = {
    # Enable receiving requests to dnsmasq from the ethernet port.
    networking.firewall.interfaces."enp46s0".allowedUDPPorts = [ 53 67 ];
  };
}
