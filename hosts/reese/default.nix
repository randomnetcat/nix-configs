{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../presets/server.nix
    ../../presets/network.nix

    ./system.nix
    ./mounts/system
    ./zfs.nix
    ./networking.nix
    ./network-backup.nix
    ./database.nix

    ./agorabot.nix
    ./remote-build.nix
    ./prometheus.nix

    ./mastodon/personal.nix

    ./nomic-web
  ];

  nixpkgs.localSystem = {
    system = "aarch64-linux";
  };

  networking.hostId = "531e2393";

  documentation.nixos.enable = false;

  system.stateVersion = "21.11";

  boot.tmp.cleanOnBoot = true;
  networking.hostName = "reese";
  networking.firewall.allowPing = true;

  services.resolved.enable = true;

  randomcat.notifications = {
    discord = {
      enable = true;
      webhookUrlCredential = ./secrets/notify-discord-webhook;
    };

    mail = {
      enable = true;
      sender = "sys.reese@unspecified.systems";
      recipient = "sys_reese@randomcat.org";
      smtp.passwordEncryptedCredentialPath = ./secrets/notify-email-password;
    };
  };

  randomcat.services.archive-agora = {
    enable = true;
    keysCredential = ./secrets/agora-ia-config;
  };

  randomcat.services.archive-wikis = {
    enable = true;
    keysCredential = ./secrets/wiki-ia-keys;
  };

  randomcat.services.diplomacy-bot = {
    enable = true;
    tokenCredential = ./secrets/diplomacy-bot-token;
    settings = builtins.fromJSON (builtins.readFile ./diplomacy-bot/config.json);
  };

  assertions = [
    {
      assertion = !config.virtualisation.docker.enable;
      message = "Docker is not supported because it will take 169.254.0.0/16, which conflicts with Oracle's default DNS.";
    }
  ];
}
