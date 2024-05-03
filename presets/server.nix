{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../sys/wants/tailscale.nix
    ../sys/wants/auto-upgrade/auto-reboot.nix
    ../sys/impl/auto-prune-system.nix
  ];

  config = {
    time.timeZone = "UTC";

    # Simple security things
    # From https://xeiaso.net/blog/paranoid-nixos-2021-07-18
    networking.firewall.enable = true;
    nix.settings.allowed-users = [ "root" ];
    security.sudo.execWheelOnly = true;

    programs.tmux.enable = true;

    # Chosen to be when I am likely to be asleep
    system.autoUpgrade = {
      dates = "08:00";

      rebootWindow = {
        lower = "07:00";
        upper = "10:00";
      };
    };

    randomcat.services.auto-prune-system.enable = true;

    randomcat.services.tailscale = {
      enable = true;
      extraArgs = [ "--ssh" ];
    };
  };
}
