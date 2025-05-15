{ config, pkgs, ... }:

{
  config = {
    swapDevices = [
      {
        device = "/dev/disk/by-partlabel/carter-swap";
        randomEncryption.enable = true;
      }
    ];

    boot.kernelParams = [ "nohibernate" ]; # Cannot hibernate with random-encryption swap
  };
}
