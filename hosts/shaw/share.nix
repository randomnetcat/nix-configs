{ config, lib, pkgs, ... }:

{
  config = {
    users.users.randomcat = {
      isNormalUser = true;
      group = "randomcat";
      extraGroups = [ "users" ];
    };

    users.groups.randomcat = { };

    users.users.sys-groves = {
      isSystemUser = true;
      group = "sys-groves";
    };

    users.groups.sys-groves = {
    };

    services.samba = {
      enable = true;
      nmbd.enable = false;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "shaw";
          "netbios name" = "shaw";
          "security" = "user";
          "interfaces" = "lo tailscale0";
        };

        archive = {
          "path" = "/srv/archive";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "archive";
          "force group" = "archive";
          "valid users" = "randomcat sys-groves";
          "write list" = "randomcat";
        };
      };
    };
  };
}
