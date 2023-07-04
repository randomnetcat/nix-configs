{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.mail;
  primary = cfg.primaryDomain;
in
{
  config = {
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "jason.e.cobb@gmail.com";

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = {
      virtualHosts = {
        "acmechallenge.${primary}" = {
          serverAliases = [ "*.${primary}" ];

          locations."/.well-known/acme-challenge" = {
            root = "/var/lib/acme/.challenges";
          };

          locations."/" = {
            return = "301 https://$host$request_uri";
          };
        };
      };
    };

    security.acme.certs."${primary}" = {
      webroot = "/var/lib/acme/.challenges";
      email = "jason.e.cobb@gmail.com";

      # Ensure that the certificate's key does not change. This is required because the public key
      # is hashed for the TLSA DNS record.
      extraLegoRenewFlags = [ "--reuse-key" ];

      extraDomainNames = [
        "mail.${primary}"
        "mta-sts.${primary}"
        "www.${primary}"
      ] ++ (lib.concatMap (d: [
        "mta-sts.${d}"
      ]) cfg.extraDomains);
    };
  };
}
