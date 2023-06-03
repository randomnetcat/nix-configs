{ config, lib, pkgs, ... }:

{
  config = {
    virtualisation.libvirtd.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = [ pkgs.virt-manager ];
    virtualisation.spiceUSBRedirection.enable = true;

    virtualisation.virtualbox.host.enable = true;
  };
}
