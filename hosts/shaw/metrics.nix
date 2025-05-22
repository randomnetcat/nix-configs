{ config, lib, pkgs, ... }:

{
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
