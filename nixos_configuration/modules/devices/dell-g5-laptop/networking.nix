{ config, pkgs, ... }:

{
  imports = [
    ../../impl/networking/wifi.nix
  ];

  options = {
  };

  config = {
    networking.hostName = "randomcat-laptop-nixos"; # Define your hostname.

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;
    networking.interfaces.enp60s0.useDHCP = true;
    networking.interfaces.wlo1.useDHCP = true;

    environment.systemPackages = [
      pkgs.gnome3.networkmanagerapplet
      pkgs.gnome3.networkmanager_openvpn
      pkgs.gnome3.networkmanager_openconnect
    ];
  };
}
