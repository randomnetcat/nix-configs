{ config, lib, pkgs, ... }:

{
  config = {
    services.nginx.virtualHosts = {
      "janet.tel" = {
        addSSL = true;
        enableACME = true;

        locations."/" = {
          return = "302 https://unspecified.systems";
        };
      };

      "unspecified.systems" = {
        addSSL = true;
        acmeRoot = config.security.acme.certs."unspecified.systems".webroot;
        useACMEHost = "unspecified.systems";

        serverAliases = [ "www.unspecified.systems" ];

        locations."/".root = "${./home}";
      };

      "mail.unspecified.systems" = {
        addSSL = true;
        acmeRoot = config.security.acme.certs."unspecified.systems".webroot;
        useACMEHost = "unspecified.systems";

        locations."/" = {
          return = "302 https://unspecified.systems";
        };
      };
    };
  };
}
