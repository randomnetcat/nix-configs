{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    home.packages = [
      pkgs.killall
      pkgs.p7zip
      pkgs.file
    ];

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

    programs.bash = {
      enable = true;

      initExtra = ''
        if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; fi
        if [ -e "/etc/profiles/per-user/randomcat/etc/profile.d/hm-session-vars.sh" ]; then . "/etc/profiles/per-user/randomcat/etc/profile.d/hm-session-vars.sh"; fi
      '';

      shellAliases = {
        ls = "ls -l";
      };
    };

    programs.jq.enable = true;

    home.sessionVariables = {
      EDITOR = config.home.sessionVariables.VISUAL;
      VISUAL = "vim";
    };
  };
}
