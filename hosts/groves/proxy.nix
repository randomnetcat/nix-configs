{ config, lib, pkgs, ... }:

{
  config = {
    services.nginx = {
      enable = true;

      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
    };
  };
}
