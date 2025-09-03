{ config, lib, pkgs, ... }:

{
  imports = [
    ./sites
  ];

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
    networking.nat.externalInterface = "enp0s6";

    services.nginx.virtualHosts."jecobb.com" = {
      forceSSL = true;
      enableACME = true;

      locations."/".return = "307 https://randomcat.org/portfolio";
    };

    services.nginx.virtualHosts."nomic.space" = {
      forceSSL = true;
      enableACME = true;
    };

    services.nginx.virtualHosts."dance.a.powerful.dance" = {
      forceSSL = true;
      enableACME = true;

      locations."= /".return = "302 https://agora-ruleset.gaelan.me/#Rule2029";
    };
  };
}
