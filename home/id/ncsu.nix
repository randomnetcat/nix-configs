{ config, lib, pkgs, ... }:

{
  config = {
    programs.git = {
      userEmail = "jecobb2@ncsu.edu";
      userName = "Janet Cobb";
    };
  };
}
