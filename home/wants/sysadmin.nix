{ pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.gparted
      pkgs.smartmontools
      pkgs.lshw
      pkgs.usbutils
    ];
  };
}
