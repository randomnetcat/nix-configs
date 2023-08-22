{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    time.timeZone = "UTC";

    # Simple security things
    # From https://xeiaso.net/blog/paranoid-nixos-2021-07-18
    networking.firewall.enable = true;
    nix.settings.allowed-users = [ "root" ];
    security.sudo.execWheelOnly = true;
  };
}
