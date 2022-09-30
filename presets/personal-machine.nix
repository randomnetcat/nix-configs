{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
    ../sys/user/randomcat.nix
    ../sys/wants/development/common.nix
  ];

  config = {
    home-manager.users.randomcat.imports = map (x: ../home/wants + "/${x}.nix") [
      "communication"
      "custom-gnome"
      "custom-terminal"
      "general-development"
      "java-development"
      "keybase"
      "media-creation"
      "ncsu"
      "nixops"
      "nomic"
      "sysadmin"
      "web-browsing"
    ] ++ [
      ../home/id/personal.nix
    ];
  };
}
