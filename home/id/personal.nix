{ config, lib, pkgs, ... }:

{
  config = {
    programs.git = {
      settings = {
        user.name = "Janet Cobb";
        user.email = "git@randomcat.org";
      };
    };
  };
}
