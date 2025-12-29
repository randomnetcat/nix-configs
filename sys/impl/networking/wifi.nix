{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = {
    networking.networkmanager.enable = true; # Use NetworkManager for wifi

    users.users.randomcat.extraGroups = [ "networkmanager" ];
  };
}
