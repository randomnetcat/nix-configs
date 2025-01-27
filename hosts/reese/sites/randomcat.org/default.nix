{ config, lib, pkgs, ... }:

{
  config = {
    services.nginx.virtualHosts."randomcat.org" = {
      default = true;

      forceSSL = true;
      enableACME = true;

      locations."/".return = "307 https://randomnetcat.github.io$request_uri";
    };
  };
}
