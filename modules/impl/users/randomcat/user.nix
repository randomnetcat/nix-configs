{ conifg, pkgs, lib, ... }:

{
  config = {
    users.users.randomcat = {
      isNormalUser = true;
      group = "randomcat";
      home = "/home/randomcat";
      extraGroups = [ "users" "wheel" ]; # Enable ‘sudo’ for the user.
    };

    users.groups.randomcat = {
      members = [ "randomcat" ];
    };
  };
}
