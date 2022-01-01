{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/impl/global.nix
    ../../modules/impl/boot/systemd-boot.nix

    ./mounts/system

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
