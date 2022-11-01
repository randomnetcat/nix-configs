{ config, pkgs, lib, ... }:

{
  config = {
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
  };
}
