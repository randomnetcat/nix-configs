{ config, pkgs, lib, ... }:

{
  config = {
    users.users.randomcat = {
      uid = 1000;
      isNormalUser = true;
      group = "randomcat";
      home = "/home/randomcat";
      extraGroups = [ "users" "wheel" ]; # Enable ‘sudo’ for the user.
      description = "Janet";
    };

    users.groups.randomcat = {
      gid = config.users.users.randomcat.uid;
      members = [ "randomcat" ];
    };

    home-manager.users.randomcat = {
      home.username = "randomcat";
      home.homeDirectory = config.users.users.randomcat.home;
      home.stateVersion = "21.05";
    };
  };
}
