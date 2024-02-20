{ config, pkgs, lib, ... }:

{
  config = {
    randomcat.services.tailscale = {
      enable = true;
      extraArgs = [ "--ssh" ];
    };
  };
}
