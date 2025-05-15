{ config, pkgs, ... }:

{
  imports = [
    ./ephemeral.nix
    ./root.nix
    ./swap.nix
    ./tmp.nix
  ];

  options = { };

  config = {
    boot.initrd.supportedFilesystems = [ "zfs" ];
    boot.supportedFilesystems = [ "zfs" ];

    boot.kernelParams = [ "nohibernate" ]; # Cannot hibernate with ZFS
  };
}
