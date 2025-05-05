{ config, lib, pkgs, ... }:

{
  config = {
    randomcat.services.backups = {
      fromNetwork = true;

      source.ssh = {
        enable = true;
        enableVpnAddresses = true;
      };
    };
  };
}
