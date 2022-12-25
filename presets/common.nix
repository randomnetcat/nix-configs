{ config, lib, pkgs, ... }:

{
  imports = [
    ../sys/impl/networking/resolved.nix
    ../sys/impl/nix/version.nix
    ../sys/impl/maintenance
    ../sys/impl/zfs-common.nix
  ];

  config = {
    nix.registry.nixpkgs.to = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = config.system.nixos.revision;
    };

    environment.etc."active-nixpkgs-source".source = "${pkgs.path}";
    nix.nixPath = [ "nixpkgs=/etc/active-nixpkgs-source" ];

    nixpkgs.config.allowUnfree = true;
  };
}
