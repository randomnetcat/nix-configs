{ config, lib, pkgs, ... }:

{
  config = {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "jason.e.cobb@gmail.com";

    services.nginx = {
      enable = true;

      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
    };

    networking.nat.enable = true;
    networking.nat.externalInterface = "enp0s3";
  };
}
