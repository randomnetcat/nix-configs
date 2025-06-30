{ config, lib, pkgs, ... }:

{
  imports = [
    ../../sys/user/randomcat.nix
  ];

  config = {
    users.users.archive = {
      uid = 2000;
      isSystemUser = true;
      group = "archive";
    };

    users.groups.archive = {
      gid = config.users.users.archive.uid;
    };
  };
}
