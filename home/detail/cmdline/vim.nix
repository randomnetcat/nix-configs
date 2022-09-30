{ config, lib, pkgs, ... }:

{
  config = {
    programs.vim = {
      enable = true;

      settings = {
        expandtab = false;
        tabstop = 4;
        shiftwidth = 4;
        number = true;
        undodir = [ "~/.vim/undo" ];
        undofile = true;
      };

      plugins = [ pkgs.vimPlugins.vim-sensible pkgs.vimPlugins.vim-mundo ];

      extraConfig = ''
        set hls
        nnoremap <F5> :MundoToggle<CR>
      '';
    };

    home.file.".vim/undo/.hm_keep".text = "";


  };
}
