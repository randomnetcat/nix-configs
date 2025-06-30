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
    nix = {
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
