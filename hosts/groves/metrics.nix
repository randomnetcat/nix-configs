{ config, lib, pkgs, ... }:

let
  tailscaleIP = "100.68.110.33";
in
{
  imports = [
    ../../sys/wants/export-metrics.nix
  ];

  config = {
    randomcat.services.export-metrics = {
      enable = true;
      listenAddress = tailscaleIP;

      exports = {
        node = { };
        nvidia-gpu = { };
        systemd = { };
        zfs = { };
      };
    };
  };
}
