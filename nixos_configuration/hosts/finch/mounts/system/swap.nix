{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    swapDevices = [
      { device = "/dev/disk/by-label/swap"; }
    ];
  };
}
