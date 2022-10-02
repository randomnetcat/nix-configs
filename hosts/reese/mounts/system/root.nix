{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/" = zfsMount "system/root";
    fileSystems."/var" = zfsMount "system/var";
    fileSystems."/nix" = zfsMount "local/nix";
  };
}
