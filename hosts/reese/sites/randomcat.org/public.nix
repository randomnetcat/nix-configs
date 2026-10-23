{ config, lib, pkgs, ... }:

{
  config = {
    systemd.tmpfiles.rules = [
      "d /srv/web-public 0755 ${config.users.users.nginx.name} ${config.users.groups.nginx.name} -"
    ];

    services.nginx.virtualHosts."randomcat.org" = {
      locations."/public/" = {
        alias = "/srv/web-public/";
      };
    };
  };
}
