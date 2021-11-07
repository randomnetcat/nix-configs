{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    home.packages = [
      pkgs.killall
      pkgs.p7zip
    ];

    programs.vim = {
      enable = true;

      settings = {
        expandtab = true;
        undodir = [ "~/.vim/undo" ];
        undofile = true;
      };

      plugins = [ pkgs.vimPlugins.vim-sensible pkgs.vimPlugins.vim-mundo ];

      extraConfig = ''
        set hls
        nnoremap <F5> :MundoToggle<CR>
      '';
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
