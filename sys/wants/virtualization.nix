{ config, lib, pkgs, ... }:

{
  config = {
    virtualisation.libvirtd = {
      enable = true;

      qemu.vhostUserPackages = [
        pkgs.virtiofsd
      ];

      qemu.swtpm.enable = true;
    };

    programs.dconf.enable = true;
    environment.systemPackages = [ pkgs.virt-manager ];
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
