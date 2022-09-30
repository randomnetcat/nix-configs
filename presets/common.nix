{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../sys/impl/networking/resolved.nix
    ../sys/impl/nix/version.nix
  ];

  config = {
    nix.registry.nixpkgs.to = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = inputs.nixpkgs.rev;
      narHash = inputs.nixpkgs.narHash;
    };

    environment.etc."active-nixpkgs-source".source = "${inputs.nixpkgs}";
    nix.nixPath = [ "nixpkgs=/etc/active-nixpkgs-source" ];

    nixpkgs.config.allowUnfree = true;
  };
}
