{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../sys/wants/auto-upgrade/auto-reboot.nix
  ];

  config = {
    time.timeZone = "UTC";

    # Simple security things
    # From https://xeiaso.net/blog/paranoid-nixos-2021-07-18
    networking.firewall.enable = true;
    nix.settings.allowed-users = [ "root" ];
    security.sudo.execWheelOnly = true;

    # Chosen to be when I am likely to be asleep
    system.autoUpgrade.rebootWindow = {
      lower = "07:00";
      upper = "10:00";
    };
  };
}
