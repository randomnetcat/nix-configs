{ pkgs, lib, ... }:

{
  config = {
    users.users.archive = {
      isNormalUser = true;
      group = "archive";
    };

    users.groups.archive = {};
  };
}
