{ config, lib, pkgs, ... }:

let
  tailscaleIP = config.randomcat.network.hosts.${config.networking.hostName}.tailscaleIP4;
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
        systemd = { };
        zfs = { };
      };
    };
  };
}
