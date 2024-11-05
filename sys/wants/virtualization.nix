{ config, lib, pkgs, ... }:

{
  config = {
    virtualisation.libvirtd = {
      enable = true;

      qemu.vhostUserPackages = [
        pkgs.virtiofsd
      ];
    };

    programs.dconf.enable = true;
    environment.systemPackages = [ pkgs.virt-manager ];
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
