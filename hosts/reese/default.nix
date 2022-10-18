{ config, pkgs, modulesPath, inputs, ... }:
{
  deployment.targetHost = "reese";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../presets/server.nix
    ../../sys/wants/agorabot-server
    ../../sys/wants/trungle-access.nix
    ../../sys/wants/tailscale.nix
    ../../sys/impl/secrets

    ./system.nix
    ./wiki.nix
    ./agorabot.nix
    ./mounts/system
  ];

  networking.hostId = "531e2393";
  # systemd.network.enable = true;
  # networking.useNetworkd = true;
  # networking.useDHCP = true;
  # networking.interfaces.enp0s3.useDHCP = true;

  documentation.nixos.enable = false;

  # hardware.cpu.amd.updateMicrocode = true;
  # hardware.enableRedistributableFirmware = true;

  system.stateVersion = "21.11";

  boot.cleanTmpDir = true;
  networking.hostName = "reese";
  networking.firewall.allowPing = true;

  users.users.remote-build = {
    isNormalUser = true;
    group = "remote-build";
  };

  users.groups.remote-build = {};

  nix.settings.trusted-users = [ "remote-build" ];

  age.identityPaths = [
    "/root/host_keys/ssh_host_ed25519_key"
    "/root/host_keys/ssh_host_rsa_key"
  ];

  features.trungle-access.enable = true;

  services.resolved.enable = true;

  services.resolved.extraConfig = ''
    DNS=1.1.1.1%enp0s3#cloudflare-dns.com 1.0.0.1%enp0s3#cloudflare-dns.com 2606:4700:4700::1111%enp0s3#cloudflare-dns.com 2606:4700:4700::1001%enp0s3#cloudflare-dns.com
  '';

  randomcat.services.tailscale = {
    enable = true;
    authkeyPath = "/run/keys/tailscale-authkey";
    extraArgs = [ "--advertise-exit-node" "--ssh" ];
  };

  randomcat.secrets.secrets."tailscale-authkey" = {
    encryptedFile = ./secrets/tailscale-authkey;
    dest = "/run/keys/tailscale-authkey";
    owner = "root";
    group = "root";
    permissions = "700";
  };
}
