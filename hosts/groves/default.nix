{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../presets/personal-machine.nix
    ../../sys/wants/tailscale.nix
    ../../sys/impl/builders

    ./mounts/system

    ./boot.nix
    ./graphical.nix
    ./networking.nix
    ./locale.nix
    ./filesystem.nix

    # Features
    ./gaming.nix
    ./backup.nix
    ./bluetooth.nix
    ./printing.nix
    ./security.nix
    ./vms.nix
  ];

  options = {
  };

  config = {
    nixpkgs.localSystem = {
      system = "x86_64-linux";
    };

    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    randomcat.services.tailscale = {
      enable = true;
      extraArgs = [ "--operator=randomcat" ];
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
