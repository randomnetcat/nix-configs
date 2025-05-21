{ config, lib, pkgs, ... }:

{
  imports = [
    ../../sys/wants/export-metrics.nix
  ];

  config = {
    randomcat.services.export-metrics = {
      enable = true;
      tailscaleOnly = true;

      exports = {
        node = { };
        zfs = { };
      };
    };
  };
}
