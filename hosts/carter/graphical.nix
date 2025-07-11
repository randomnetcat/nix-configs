{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sys/impl/graphical/gnome-gdm.nix
  ];

  config = {
    services.xserver.videoDrivers = [ "amd" ];
    boot.initrd.kernelModules = [ "amdgpu" ];

    # Fix graphical artifacts
    # https://bbs.archlinux.org/viewtopic.php?id=296990
    boot.kernelParams = [
      "amdgpu.dcdebugmask=0x410"
      "amdgpu.sg_display=0"
    ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
