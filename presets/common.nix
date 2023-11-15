{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../sys/impl/networking/resolved.nix
    ../sys/impl/nix/version.nix
    ../sys/impl/maintenance
    ../sys/impl/zfs-common.nix
    ../sys/impl/ssh-security.nix
  ];

  config = {
    nix.registry.nixpkgs.to = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs.rev;
      narHash = inputs.nixpkgs.narHash;
      lastModified = inputs.nixpkgs.lastModified;
    };

    nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

    nixpkgs.config.allowUnfree = true;

    assertions = [
      {
        assertion = config.system.nixos.revision == inputs.nixpkgs.rev;
        message = "NixOS pkgs revision should match nixpkgs input revision";
      }

      {
        assertion = inputs.nixpkgs.outPath == (toString pkgs.path);
        message = "Nixpkgs path (${inputs.nixpkgs.outPath}) should be the same as nixpkgs input (${toString pkgs.path})";
      }
    ];
  };
}
