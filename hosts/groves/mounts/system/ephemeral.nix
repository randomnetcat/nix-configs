{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/mnt/ephemeral" = (zfsMount "local/ephemeral");
  };
}
