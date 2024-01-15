{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    swapDevices = [
      {
        device = "/dev/disk/by-partlabel/groves-swap-1";
        randomEncryption.enable = true;
      }
    ];

    boot.kernelParams = [ "nohibernate" ]; # Cannot hibernate with random-encryption swap
  };
}
