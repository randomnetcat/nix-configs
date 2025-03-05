{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = {
    programs.git = {
      enable = true;
      aliases = { fpush = "push --force-with-lease"; };
      package = pkgs.gitAndTools.gitFull;

      ignores = [
        "*~"
        "*.swp"

        "local" 

        ".envrc" 
        ".direnv/" 

        ".idea/"
        "*.iml"

        "__pycache__"
      ];

      difftastic.enable = true;

      extraConfig = {
        pull.rebase = true;
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
      };
    };
  };
}
