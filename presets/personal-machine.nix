{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../sys/user/randomcat.nix
    ../sys/wants/development/common.nix
    ../sys/wants/virtualization.nix
  ];

  config = {
    home-manager.users.randomcat.imports = map (x: ../home/wants + "/${x}.nix") [
      "communication"
      "cpp-development"
      "custom-gnome"
      "custom-terminal"
      "deployment"
      "general-development"
      "java-development"
      "media-consumption"
      "media-creation"
      "ncsu"
      "nomic"
      "sysadmin"
      "web-browsing"
    ] ++ [
      ../home/id/personal.nix

      {
        _module.args.inputs = inputs;
      }
    ];

    users.users.randomcat.extraGroups = [ "libvirtd" ];
  };
}
