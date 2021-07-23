{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    programs.vim = {
      enable = true;
    };

    programs.bash = {
      enable = true;

      initExtra = ''
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      '';

      shellAliases = {
        ls = "ls -l";
      };
    };

    home.sessionVariables = {
      EDITOR = config.home.sessionVariables.VISUAL;
      VISUAL = "vim";
    };
  };
}