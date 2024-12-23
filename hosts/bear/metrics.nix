{ config, lib, pkgs, ... }:

let
  tailscaleIP = "100.85.165.130";
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
        zfs = { };

        maddy = {
          enableService = false;
          localPort = 9749;
        };
      };
    };
  };
}
