{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../sys/user/randomcat.nix
    ../sys/wants/development/common.nix
    ../sys/wants/virtualization.nix
    ../sys/wants/android.nix
    ../sys/wants/auto-upgrade/manual-reboot.nix
    ../sys/wants/tailscale.nix
    ../sys/impl/graphical/gnome-gdm.nix
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

    users.users.randomcat.extraGroups = [
      "libvirtd"
      "adbusers"
      "vboxusers"
    ];

    randomcat.services.tailscale = {
      enable = true;

      extraArgs = [
        "--login-server=https://headscale.unspecified.systems"
      ];
    };

    services.openssh = {
      enable = true;
      openFirewall = true;
    };

    services.automatic-timezoned.enable = true;

    # Required for automatic-timezoned to work. See https://github.com/NixOS/nixpkgs/issues/68489
    services.geoclue2.enableDemoAgent = lib.mkForce true;

    programs._1password-gui = {
      enable = true;

      polkitPolicyOwners = [
        config.users.users.randomcat.name
      ];
    };

    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    programs.steam.enable = true;
    services.joycond.enable = true;

    # Ensure nixpkgs source is kept so it isn't constantly redownloaded.
    system.extraDependencies = [
      inputs.nixpkgs.outPath
    ];
  };
}
