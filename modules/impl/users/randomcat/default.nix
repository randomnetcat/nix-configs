{ config, pkgs, ... }:

let
  username = "randomcat";
  homeDirectory = "/home/randomcat";
in
{
  imports = [
  ];

  options = {
  };

  config = {
    users.users."${username}" = {
      isNormalUser = true;
      group = "randomcat";
      home = homeDirectory;
      extraGroups = [ "users" "wheel" ]; # Enable ‘sudo’ for the user.
    };

    users.groups."${username}" = {
      members = [ "${username}" ];
    };

    home-manager.users."${username}" = {
      imports = [
        (import ./home { inherit username homeDirectory; })
      ];
    };
  };
}
