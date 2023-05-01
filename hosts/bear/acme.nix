{ config, lib, pkgs, ... }:

{
  config = {
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "jason.e.cobb@gmail.com";

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = {
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

      # Ensure that the certificate's key does not change. This is required because the public key
      # is hashed for the TLSA DNS record.
      extraLegoRenewFlags = [ "--reuse-key" ];

      extraDomainNames = [
        "mail.unspecified.systems"
        "mta-sts.unspecified.systems"
        "www.unspecified.systems"
      ];
    };
  };
}
