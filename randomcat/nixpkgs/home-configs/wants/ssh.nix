{ config, lib, pkgs, ... }:

{
  imports = [
    ../vendor/impermanence/home-manager.nix
  ];

  options = {
  };

  config = {
    programs.ssh.enable = true;
  };
}
