{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/tmp" = (zfsMount "local/tmp/root") // { neededForBoot = true; };
    fileSystems."/var/tmp" = (zfsMount "local/tmp/var") // { neededForBoot = true; };
  };
}
