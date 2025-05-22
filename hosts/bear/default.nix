{ config, pkgs, modulesPath, inputs, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../presets/server.nix
    ../../presets/network.nix

    ./system.nix
    ./mounts/system
    ./zfs.nix

    ./nginx.nix
    ./web.nix

    ./mail
    ./auth

    ./backup.nix
    ./networking.nix
    ./metrics.nix
  ];

  networking.hostId = "b3302af3";

  documentation.nixos.enable = false;

  system.stateVersion = "23.05";

  boot.tmp.cleanOnBoot = true;
  networking.hostName = "bear";
  networking.firewall.allowPing = true;

  services.resolved.enable = true;
  services.resolved.dnssec = "false";

  randomcat.notifications.discord = {
    enable = true;
    webhookUrlCredential = ./secrets/notify-discord-webhook;
  };
}
