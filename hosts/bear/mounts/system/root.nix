{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/" = zfsMount "safe/system/root";
    fileSystems."/var" = zfsMount "safe/system/var";
    fileSystems."/nix" = zfsMount "local/nix";
    fileSystems."/tmp" = zfsMount "local/tmp/root" // { neededForBoot = true; };
    fileSystems."/var/tmp" = zfsMount "local/tmp/var" // { neededForBoot = true; };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/E328-28DD";
      fsType = "vfat";

      options = [
        "uid=0"
        "gid=0"
        "umask=077"
      ];
    };
  };
}
