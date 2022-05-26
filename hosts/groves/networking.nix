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
    networking.interfaces.enp46s0.useDHCP = true;
    networking.interfaces.wlp0s20f3.useDHCP = true;

    environment.systemPackages = [
      pkgs.networkmanagerapplet
      pkgs.networkmanager-openvpn
      pkgs.networkmanager-openconnect
    ];
  };
}
