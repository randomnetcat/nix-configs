{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../presets/server.nix
    ../../sys/impl/notifications.nix

    ./mounts/system.nix
    ./mounts/data.nix

    ./boot.nix
    ./networking.nix
    ./filesystem.nix

    ./archive.nix
    ./backup
    ./share.nix
    ./playback.nix
    ./ssh.nix
  ];

  options = {
  };

  config = {
    nixpkgs.localSystem = {
      system = "x86_64-linux";
    };

    # boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    networking.hostName = "shaw";
    networking.hostId = "df7b2245";

    randomcat.notifications = {
      enable = true;
      sender = "sys.shaw@unspecified.systems";
      recipient = "sys_shaw@randomcat.org";
      smtp.passwordEncryptedCredentialPath = ./secrets/notify-email-password;
    };

    services.fwupd.enable = true;

    system.autoUpgrade.allowReboot = false;
    system.autoUpgrade.rebootWindow = null;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.11"; # Did you read the comment?
  };
}
