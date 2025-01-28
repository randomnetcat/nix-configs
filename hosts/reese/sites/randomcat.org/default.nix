{ config, lib, pkgs, ... }:

{
  config = {
    services.nginx.virtualHosts."randomcat.org" = {
      default = true;

      forceSSL = true;
      enableACME = true;

      locations."/".return = "307 https://randomnetcat.github.io$request_uri";

      locations."= /cpp_initialization/initialization.svg" = {
        proxyPass = "https://raw.githubusercontent.com/randomnetcat/cpp_initialization/gh-pages/initialization.svg";
        recommendedProxySettings = false;

        extraConfig = ''
          proxy_set_header Host "raw.githubusercontent.com";
        '';
      };

      locations."= /cpp_initialization/initialization.png" = {
        proxyPass = "https://raw.githubusercontent.com/randomnetcat/cpp_initialization/gh-pages/initialization.png";
        recommendedProxySettings = false;

        extraConfig = ''
          proxy_set_header Host "raw.githubusercontent.com";
        '';
      };
    };
  };
}
