{ config, pkgs, ... }:

{
  imports = [
    ../../modules/impl/networking/wifi.nix
  ];

  options = {
  };

  config = {
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
