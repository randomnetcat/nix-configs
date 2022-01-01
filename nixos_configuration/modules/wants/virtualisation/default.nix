{ pkgs, lib, ... }:

{
  config = {
    virtualisation.libvirtd.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = [ pkgs.virt-manager ];

    users.users.randomcat.extraGroups = [ "libvirtd" ];
  };
}
