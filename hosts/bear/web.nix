{ config, lib, pkgs, ... }:

{
  config = {
    services.nginx.virtualHosts."unspecified.systems" = {
      useACMEHost = "unspecified.systems";
      serverAliases = [ "www.unspecified.systems" ];
      addSSL = true;

      locations."/".root = "${./home}";
    };
  };
}
