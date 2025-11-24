{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = { };

  config = {
    programs.git = {
      enable = true;
      aliases = { fpush = "push --force-with-lease"; };
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

      difftastic.enable = true;

      extraConfig = {
        pull.rebase = true;
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
      };
    };
  };
}
