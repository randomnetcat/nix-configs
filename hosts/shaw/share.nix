{ config, lib, pkgs, ... }:

{
  config = {
    users.users.randomcat = {
      isNormalUser = true;
      group = "randomcat";
      extraGroups = [ "users" ];
    };

    users.groups.randomcat = { };

    services.samba = {
      enable = true;
      nmbd.enable = false;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "shaw";
          "netbios name" = "shaw";
          "security type" = "user";
          "interfaces" = "lo tailscale0";
        };

        archive = {
          "path" = "/srv/archive";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "archive";
          "force group" = "archive";
          "valid users" = "randomcat";
        };
      };
    };
  };
}
