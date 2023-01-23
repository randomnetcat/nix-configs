{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    programs.git = {
      enable = true;
      ignores = [ ".idea/" "*~" "*.iml" "local" ".envrc" ".direnv/" ];
      aliases = { fpush = "push --force-with-lease"; };
      package = pkgs.gitAndTools.gitFull;

      extraConfig = {
        pull.rebase = true;
        init.defaultBranch = "main";
      };
    };
  };
}
