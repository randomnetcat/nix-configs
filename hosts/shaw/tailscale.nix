{ config, pkgs, lib, ... }:

{
  config = {
    randomcat.services.tailscale = {
      enable = true;
      extraArgs = [ "--advertise-exit-node" "--ssh" ];
    };
  };
}
