{ config, lib, pkgs, ... }:

{
  imports = [
    ../../impl/development/man.nix
    ../../impl/development/binfmt.nix
    ../../impl/development/derivations.nix
  ];
}
