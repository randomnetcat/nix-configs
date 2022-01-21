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
      pkgs.networkmanagerapplet
      pkgs.networkmanager_openvpn
      pkgs.networkmanager_openconnect
    ];
  };
}
