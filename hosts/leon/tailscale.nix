{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sys/wants/tailscale.nix
  ];

  config = {
    randomcat.services.tailscale = {
      enable = true;
      extraArgs = [ "--ssh" ];
    };
  };
}
