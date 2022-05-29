{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/impl/global.nix
    ../../modules/wants/tailscale.nix

    ./mounts/system

    ./boot.nix
    ./graphical.nix
    ./networking.nix
    ./locale.nix
    ./filesystem.nix

    # Features
    ./gaming.nix
    ./development.nix
    ./backup.nix
    ./bluetooth.nix
    ./printing.nix
    ./security.nix
  ];

  options = {
  };

  config = {
    randomcat.services.tailscale = {
      enable = true;
      authkeyPath = "/root/secrets/tailscale-authkey";
    };

    networking.hostName = "groves";
    networking.hostId = "8556b001";

    services.fwupd.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?
  };
}
