{ config, pkgs, lib, ... }:

{
  imports = [
    ./locale.nix
    ./development.nix
  ];

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.11"; # Did you read the comment?

    home-manager.users.randomcat = {
      imports = let configs = ../../modules/impl/users/randomcat/home/home-configs; in [
        (configs + "/wants/custom-gnome.nix")
        (configs + "/wants/custom-terminal.nix")
        (configs + "/wants/general-development.nix")
        (configs + "/wants/version-control-ncsu.nix")
      ];

      config = {
        home.username = "randomcat";
        home.homeDirectory = config.users.users.randomcat.home;
        home.stateVersion = "21.11";
      };
    };

    environment.systemPackages = [
      pkgs.vim
      pkgs.firefox
      pkgs.libreoffice

      pkgs.steam-run

      pkgs.vscode
      pkgs.dbeaver
    ];
  };
}
