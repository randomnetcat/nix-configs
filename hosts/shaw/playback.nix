{ pkgs, lib, ... }:

{
  config = {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    users.users.jellyfin.extraGroups = [ "archive" ];
  };
}
