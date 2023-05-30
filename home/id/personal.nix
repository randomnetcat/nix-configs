{ config, lib, pkgs, ... }:

{
  config = {
    programs.git = {
      userEmail = "git@randomcat.org";
      userName = "Janet Cobb";
    };
  };
}
