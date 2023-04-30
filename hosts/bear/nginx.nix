{ config, libs, pkgs, ... }:

{
  config = {
    services.nginx = {
      enable = true;

      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
    };
  };
}
