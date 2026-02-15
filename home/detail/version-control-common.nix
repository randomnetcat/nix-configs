{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = {
    programs.git = {
      enable = true;
      package = pkgs.gitFull;

      ignores = [
        # Text editors
        "*~"
        "*.swp"

        # IDEs
        ".idea/"
        "*.iml"

        # nix direnv
        ".envrc"
        ".direnv/"

        # Programming languages
        "__pycache__"
        ".kotlin"

        # Directory for custom files
        "local"
      ];

      settings = {
        pull.rebase = true;
        push.autoSetupRemote = true;
        init.defaultBranch = "main";

        alias = {
          fpush = "push --force-with-lease";
        };
      };
    };

    programs.difftastic = {
      enable = true;
      git.enable = true;
    };
  };
}
