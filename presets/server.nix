{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
    ../sys/wants/ssh-server.nix
  ];

  config = {
  };
}
