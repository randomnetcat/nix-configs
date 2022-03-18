{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    programs.git = {
      enable = true;
      userEmail = "jason.e.cobb@gmail.com";
      userName = "Jason Cobb";
      ignores = [ ".idea/" "*~" "*.iml" "local" ];
      aliases = { fpush = "push --force-with-lease"; };
      package = pkgs.gitAndTools.gitFull;

      extraConfig = {
        pull.rebase = true;
      };
    };
  };
}
