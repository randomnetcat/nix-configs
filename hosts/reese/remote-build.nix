{ config, pkgs, lib, ... }:

{
  config = {
    users.users.remote-build = {
      isNormalUser = true;
      group = "remote-build";
    };

    users.groups.remote-build = {};

    nix.settings.trusted-users = [ "remote-build" ];
  };
}
