{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    networking.wireless.enable = false;      # Disable wpa_supplicant
    networking.networkmanager.enable = true; # Use NetworkManager for wifi

    users.users.randomcat.extraGroups = [ "networkmanager" ];
  };
}
