{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./common.nix
    ../sys/user/randomcat.nix
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  config = {
    users.users.randomcat = {
      password = "bad password";
    };

    home-manager.users.randomcat.imports = map (x: ../home/wants + "/${x}.nix") [
      "custom-gnome"
      "custom-terminal"
      "web-browsing"
    ];

    # Don't bother trying to save space in VMs
    nix.gc.automatic = lib.mkForce false;
    nix.optimise.automatic = lib.mkForce false;
    nix.settings.auto-optimise-store = lib.mkForce false;

    nixpkgs.config.allowUnfree = true;

    services.xserver = {
      enable = true;

      displayManager = {
        gdm = {
          enable = true;
        };

        autoLogin = {
          enable = true;
          user = "randomcat";
        };
      };

      desktopManager = {
        gnome.enable = true;
      };
    };

    virtualisation = {
      memorySize = 24576;
      msize = 262144;
      cores = 6;

      resolution = lib.mkDefault { x = 1920; y = 1080; };
    };
  };
}
