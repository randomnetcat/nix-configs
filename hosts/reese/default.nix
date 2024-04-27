{ config, pkgs, modulesPath, inputs, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../presets/server.nix
    ../../sys/wants/trungle-access.nix
    ../../sys/wants/tailscale.nix

    ./system.nix
    ./mounts/system
    ./zfs.nix
    ./backup.nix
    ./tailscale.nix

    ./agorabot.nix
    ./remote-build.nix
    ./prometheus.nix

    ./mastodon/personal.nix

    ./archive/agora.nix
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

}
