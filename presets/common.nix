{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../services
    ../sys/wants/backup
    ../sys/impl/networking/resolved.nix
    ../sys/impl/maintenance
    ../sys/impl/zfs-common.nix
    ../sys/impl/ssh-security.nix
    ../sys/impl/gnome-presets.nix
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
    nix.extraOptions = ''
      experimental-features = nix-command flakes
      accept-flake-config = false
    '';

    nixpkgs.config.allowUnfree = true;

    home-manager.useGlobalPkgs = true;

    assertions = [
      # {
      #   assertion = inputs.nixpkgs.outPath == (toString pkgs.path);
      #   message = "Nixpkgs path should be the same as nixpkgs input";
      # }
    ];
  };
}
