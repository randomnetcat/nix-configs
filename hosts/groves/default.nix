{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../presets/personal-machine.nix

    ./mounts/system

    ./boot.nix
    ./ephemeral.nix
    ./filesystem.nix
    ./graphical.nix
    ./networking.nix
    ./ssh.nix
    ./streaming.nix
    ./users.nix
  ];

  options = { };

  config = {
    nixpkgs.localSystem = {
      system = "x86_64-linux";
    };

    networking.hostName = "groves";
    networking.hostId = "8556b001";

    boot.kernelParams = [
      "consoleblank=60"
    ];

    # Cannot reboot due to disk encryption.
    system.autoUpgrade.rebootWindow = null;

    services.fwupd.enable = true;

    randomcat.services.backups.fromNetwork = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?
  };
}
