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

    # Features
    ./gaming.nix
    ./development.nix
    ./backup.nix
    ./bluetooth.nix
    ./printing.nix
  ];

  options = {
  };

  config = {
    randomcat.hosts.finch.proprietaryGraphics.enable = true;

    specialisation.openSourceGraphics = {
      inheritParentConfig = true;

      configuration = {
        system.nixos.tags = [ "open-source-graphics" ];
        randomcat.hosts.finch.proprietaryGraphics.enable = lib.mkForce false;
      };
    };

    randomcat.tailscale = {
      enable = true;
      authkeyPath = "/root/secrets/tailscale-authkey";
    };

    networking.hostName = "finch";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
  };
}
