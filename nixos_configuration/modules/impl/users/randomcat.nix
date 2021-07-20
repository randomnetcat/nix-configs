{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    users.users.randomcat = {
      isNormalUser = true;
      group = "randomcat";
      extraGroups = [ "users" "wheel" ]; # Enable ‘sudo’ for the user.
    };

    users.groups.randomcat = {
      members = [ "randomcat" ];
    };
  };
}
