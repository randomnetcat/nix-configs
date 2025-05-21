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

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHagOaeTR+/7FL9sErciMw30cmV/VW8HU7J3ZFU5nj9 janet@randomcat.org"
      ];
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
