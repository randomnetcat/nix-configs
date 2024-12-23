{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/home/randomcat/archive" = zfsMount "safe/archive";
  };
}
