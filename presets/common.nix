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

    nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

    nixpkgs.config.allowUnfree = true;
  };
}
