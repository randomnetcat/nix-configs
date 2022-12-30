{ ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking.hostName = "leon";
  networking.domain = "zfs.rent";
  networking.fqdn = "randomcat.zfs.rent";

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHagOaeTR+/7FL9sErciMw30cmV/VW8HU7J3ZFU5nj9 jason.e.cobb@gmail.com" 
  ];

  system.stateVersion = "23.05";
}
