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

    services.nginx.virtualHosts."randomcat.org" = {
      default = true;

      forceSSL = true;
      enableACME = true;

      locations."/".return = "307 https://randomnetcat.github.io$request_uri";
    };

    services.nginx.virtualHosts."jecobb.com" = {
      forceSSL = true;
      enableACME = true;

      locations."/".return = "307 https://randomcat.org/portfolio";
    };

    services.nginx.virtualHosts."nomic.space" = {
      forceSSL = true;
      enableACME = true;
    };
  };
}
