{ config, lib, pkgs, ... }:

{
  config = {
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "jason.e.cobb@gmail.com";

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = {
      enable = true;

      virtualHosts = {
        "acmechallenge.unspecified.systems" = {
          serverAliases = [ "*.unspecified.systems" ];

          locations."/.well-known/acme-challenge" = {
            root = "/var/lib/acme/.challenges";
          };

          locations."/" = {
            return = "301 https://$host$request_uri";
          };
        };
      };
    };

    security.acme.certs."unspecified.systems" = {
      webroot = "/var/lib/acme/.challenges";
      email = "jason.e.cobb@gmail.com";

      extraDomainNames = [ "mail.unspecified.systems" ];
    };
  };
}
