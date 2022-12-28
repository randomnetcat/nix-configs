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
  ];

  options = {
  };

  config = {
    nixpkgs.localSystem = {
      system = "x86_64-linux";
    };

    randomcat.services.tailscale = {
      enable = true;
      authkeyPath = "/root/secrets/tailscale-authkey";
      extraArgs = [ "--operator=randomcat" ];
    };

    networking.hostName = "groves";
    networking.hostId = "8556b001";

    services.fwupd.enable = true;

    boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_5_15.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
          sha256 = "0kgxznd3sfbmnygjvp9dzhzg5chxlaxk6kldxmh1y0njcrj1lciv";
        };
        version = "5.15.80";
        modDirVersion = "5.15.80";
      };
    });

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?
  };
}
