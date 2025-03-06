{ pkgs, lib, config, ... }: {
  imports = [
    ../../presets/server.nix
    ../../presets/network.nix

    ./hardware-configuration.nix

    ./tailscale.nix
    ./networking.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  swapDevices = [
    {
      device = "/var/swapfile";
      size = 4096;
      randomEncryption.enable = true;
    }
  ];

  boot.kernelParams = [
    "nohibernate"
  ];

  networking.hostId = "2b20be51";
  networking.hostName = "leon";
  networking.domain = "zfs.rent";
  networking.fqdn = "randomcat.zfs.rent";

  services.openssh.enable = true;

  # Globally available for syncoid receive
  environment.systemPackages = [
    pkgs.lzop
    pkgs.mbuffer
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHagOaeTR+/7FL9sErciMw30cmV/VW8HU7J3ZFU5nj9 jason.e.cobb@gmail.com"
  ];

  boot.supportedFilesystems = [
    "zfs"
  ];

  boot.zfs = {
    extraPools = [
      "nas_1758665d"
    ];

    requestEncryptionCredentials = false;
  };

  system.stateVersion = "23.05";
}
