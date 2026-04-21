{ config, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = let zfsMount = import ../zfs-mount.nix; in {
    boot.initrd.luks.devices = {
      "rpool-0" = {
        device = "/dev/disk/by-partlabel/shaw-rpool-0";
        preLVM = true;
      };
    };

    boot.initrd.systemd.services."zfs-import-rpool_ez8ryx" = {
      after = [ "systemd-cryptsetup@rpool\\x2d0.service" ];
      requires = [ "systemd-cryptsetup@rpool\\x2d0.service" ];
    };

    fileSystems."/" = zfsMount "safe/system";
    fileSystems."/var" = zfsMount "safe/system/var";
    fileSystems."/nix" = zfsMount "local/system/nix";
    fileSystems."/home" = zfsMount "safe/user/home";
  };
}
