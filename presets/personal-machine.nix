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
      "custom-gnome"
      "custom-terminal"
      "general-development"
      "java-development"
      "media-creation"
      "ncsu"
      "nixops"
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
