{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../network
    ../services
    ../sys/impl/networking/resolved.nix
    ../sys/impl/maintenance
    ../sys/impl/zfs-common.nix
    ../sys/impl/ssh-security.nix
    ../sys/impl/gnome-presets.nix
    ../sys/impl/notifications.nix
  ];

  config = {
    # Per https://lix.systems/add-to-config/
    nixpkgs.overlays = [
      (final: prev: {
        inherit (prev.lixPackageSets.stable)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
        ;
      })
    ];

    nix = {
      package = pkgs.lixPackageSets.stable.lix;
      channel.enable = false;

      extraOptions = ''
        experimental-features = nix-command flakes
        accept-flake-config = false
      '';
    };

    nixpkgs.config.allowUnfree = true;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      extraSpecialArgs = {
        inherit inputs;
      };
    };

    # This should help security, and I don't tend to use interesting sudo rules anyway.
    security.sudo = {
      execWheelOnly = true;
    };
  };
}
