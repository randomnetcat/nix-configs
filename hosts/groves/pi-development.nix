{ config, pkgs, lib, ... }:

{
  config = {
    # Allow non-root access to USB SD card reader so that it can be passed through
    # to a VM.
    services.udev.extraRules = ''SUBSYSTEMS=="usb" ATTRS{idVendor}=="14cd" ATTRS{idProduct}=="1212" GROUP="wheel" ENV{UDISKS_AUTO}="0"'';

    # Enable receiving requests to dnsmasq from the ethernet port.
    networking.firewall.interfaces."enp46s0".allowedUDPPorts = [ 53 67 ];
  };
}
