{ config, lib, pkgs, ... }:

{
  config = {
    services.nginx.virtualHosts."infinite.nomic.space" = {
      locations."= /discord".return = "307 https://discord.com/invite/5PMCRB6TUn";
    };
  };
}
