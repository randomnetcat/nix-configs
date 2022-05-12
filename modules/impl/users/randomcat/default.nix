{ config, pkgs, ... }:

{
  imports = [
    ./user.nix
  ];

  options = {
  };

  config = {
    home-manager.users.randomcat = {
      imports = [
        ./home
      ];

      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = "randomcat";
      home.homeDirectory = config.users.users.randomcat.home;
    };
  };
}
