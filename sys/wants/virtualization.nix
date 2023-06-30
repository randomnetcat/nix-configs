{ config, lib, pkgs, ... }:

{
  config = {
    virtualisation.libvirtd.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = [ pkgs.virt-manager ];
    virtualisation.spiceUSBRedirection.enable = true;

    virtualisation.virtualbox.host.enable = true;

    # https://www.reddit.com/r/virtualbox/comments/v75l21/stuck_starting_virtual_box_20/
    boot.kernelParams = [ "ibt=off" ];
  };
}
