{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    programs.git = {
      enable = true;
      ignores = [ ".idea/" "*~" "*.iml" "local" ".envrc" ".direnv/" "*.swp" ];
      aliases = { fpush = "push --force-with-lease"; };
      package = pkgs.gitAndTools.gitFull;

      difftastic.enable = true;

      extraConfig = {
        pull.rebase = true;
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
      };
    };
  };
}
