{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.mail;
  primary = cfg.primaryDomain;
  allDomains = [ primary ] ++ cfg.extraDomains;
in
{
  config = {
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "jason.e.cobb@gmail.com";

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = {
      virtualHosts = lib.mkMerge [
        {
          "acmechallenge.${primary}" = {
            serverAliases = [ "*.${primary}" ];

            locations."/.well-known/acme-challenge" = {
              root = "/var/lib/acme/.challenges";
            };

            locations."/" = {
              return = "301 https://$host$request_uri";
            };
          };
        }

        (lib.listToAttrs (map (domain: {
          name = "mta-sts.${domain}";

          value = {
            addSSL = true;
            acmeRoot = config.security.acme.certs."${primary}".webroot;
            useACMEHost = primary;

            locations."=/.well-known/mta-sts.txt".alias = pkgs.writeText "mta-sts.txt" ''
              version: STSv1
              mode: enforce
              max_age: 604800
              mx: mail.${primary}
            '';
          };
        }) allDomains))
      ];
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
