{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = let zfsMount = import ../zfs-mount.nix; in {
    boot.initrd.luks.devices = {
      "rpool-1" = {
        device = "/dev/disk/by-partlabel/groves-rpool-1";
        preLVM = true;
      };

      "rpool-2" = {
        device = "/dev/disk/by-partlabel/groves-rpool-2";
        preLVM = true;
      };
    };

    fileSystems."/" = zfsMount "safe/system";
    fileSystems."/var" = zfsMount "safe/system/var";
    fileSystems."/nix" = zfsMount "local/nix";
    fileSystems."/home" = zfsMount "safe/user/home";
  };
}
