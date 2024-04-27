{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../sys/user/randomcat.nix
    ../sys/wants/development/common.nix
    ../sys/wants/virtualization.nix
    ../sys/wants/android.nix
    ../sys/wants/auto-upgrade/manual-reboot.nix
  ];

  config = {
    home-manager.users.randomcat.imports = map (x: ../home/wants + "/${x}.nix") [
      "communication"
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

    users.users.randomcat.extraGroups = [
      "libvirtd"
      "adbusers"
      "vboxusers"
    ];

    # Ensure nixpkgs source is kept so it isn't constantly redownloaded.
    system.extraDependencies = [
      inputs.nixpkgs.outPath
    ];
  };
}
