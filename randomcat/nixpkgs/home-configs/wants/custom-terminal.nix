{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    home.packages = [
      pkgs.killall
    ];

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
