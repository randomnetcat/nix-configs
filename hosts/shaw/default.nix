{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../presets/server.nix
    ../../sys/wants/tailscale.nix

    ./mounts/system.nix
    ./moutns/data.nix

    ./boot.nix
    ./networking.nix
    ./filesystem.nix

    ./tailscale.nix
  ];

  options = {
  };

  config = {
    nixpkgs.localSystem = {
      system = "x86_64-linux";
    };

    # boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    randomcat.services.tailscale = {
      enable = true;
    };

    networking.hostName = "shaw";
    networking.hostId = "df7b2245";

    services.fwupd.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.11"; # Did you read the comment?
  };
}
