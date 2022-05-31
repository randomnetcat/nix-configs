{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/tmp" = zfsMount "local/tmp/root";
    fileSystems."/var/tmp" = zfsMount "local/tmp/var";
  };
}
