{ pkgs, lib, config, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./tailscale.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

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
  };

  users.users.sync-groves = {
    uid = 1001;
    isNormalUser = true;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3Cwz1mqIc0kiDDraAgyJK2GYY0pjl0U5g5fjR4KiyM groves syncoid for randomcat.zfs.rent"
    ];
  };

  users.users.sync-reese = {
    uid = 1002;
    isNormalUser = true;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICfo8KLuyakQ6J6qz8dUa4Y4xEt7aV3dD6ozk9jvvaTe reese syncoid key"
    ];
  };

  system.stateVersion = "23.05";
}
