{ config, pkgs, modulesPath, inputs, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../presets/server.nix
    ../../sys/wants/tailscale.nix

    ./system.nix
    ./mounts/system
    ./zfs.nix
    ./tailscale.nix

    ./nginx.nix
    ./web.nix

    ./mail
  ];

  networking.hostId = "b3302af3";

  documentation.nixos.enable = false;

  system.stateVersion = "23.05";
  home-manager.users.root.home.stateVersion = "23.05";

  boot.tmp.cleanOnBoot = true;
  networking.hostName = "bear";
  networking.firewall.allowPing = true;

  services.resolved.enable = true;

  services.resolved.extraConfig = ''
    DNS=8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google
  '';
}
