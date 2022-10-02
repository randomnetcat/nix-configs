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

    fileSystems."/efi" = {
      device = "/dev/disk/by-uuid/1B91-2431";
      fsType = "vfat";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/a6597143-a4b8-49f3-b4d2-b2e42c9dd866";
      fsType = "ext4";
    };
  };
}
