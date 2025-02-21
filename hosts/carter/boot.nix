{ pkgs, lib, ... }:

{
  config = {
    boot.loader.grub.enable = false;

    boot.loader.systemd-boot = {
      enable = false;
      editor = false;
      memtest86.enable = true;
    };

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    boot.loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    environment.systemPackages = [
      pkgs.sbctl
    ];

    boot.loader.generationsDir.copyKernels = true;

    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/carter-esp";
      fsType = "vfat";

      options = [
        "uid=0"
        "gid=0"
        "umask=077"
      ];
    };
  };
}
