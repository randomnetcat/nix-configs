{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../presets/personal-machine.nix
    ../../presets/network.nix
    ../../sys/impl/builders

    ./mounts/system

    ./boot.nix
    ./graphical.nix
    ./networking.nix
    ./locale.nix
    ./power.nix

    ./backup.nix
    ./development.nix
    ./gaming.nix
    ./printing.nix
    ./security.nix
    ./vms.nix
  ];

  options = { };

  config = {
    nixpkgs.localSystem = {
      system = "x86_64-linux";
    };

    networking.hostName = "carter";
    networking.hostId = "2a9d39b2";

    services.fwupd.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?
  };
}
