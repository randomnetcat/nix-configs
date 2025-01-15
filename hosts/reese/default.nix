{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../presets/server.nix
    ../../presets/network.nix
    ../../sys/wants/trungle-access.nix
    ../../sys/impl/notifications.nix

    ./system.nix
    ./mounts/system
    ./zfs.nix
    ./networking.nix
    ./backup.nix
    ./network-backup.nix
    ./birdsong.nix

    ./agorabot.nix
    ./remote-build.nix
    ./prometheus.nix

    ./mastodon/personal.nix

    ./archive/wiki.nix

    ./diplomacy-bot
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

  features.trungle-access.enable = true;

  services.resolved.enable = true;

  services.resolved.extraConfig = ''
    DNS=1.1.1.1%enp0s6#cloudflare-dns.com 1.0.0.1%enp0s6#cloudflare-dns.com 2606:4700:4700::1111%enp0s6#cloudflare-dns.com 2606:4700:4700::1001%enp0s6#cloudflare-dns.com
  '';

  randomcat.notifications = {
    enable = true;
    sender = "sys.reese@unspecified.systems";
    recipient = "sys_reese@randomcat.org";
    smtp.passwordEncryptedCredentialPath = ./secrets/notify-email-password;
  };

  randomcat.services.archive-agora = {
    enable = true;
    keysCredential = ./secrets/agora-ia-config;
  };
}
