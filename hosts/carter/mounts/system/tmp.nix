{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/tmp" = (zfsMount "local/system/tmp") // { neededForBoot = true; };
    fileSystems."/var/tmp" = (zfsMount "local/system/var-tmp") // { neededForBoot = true; };
  };
}
