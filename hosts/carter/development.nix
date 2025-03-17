{ config, lib, pkgs, ... }:

{
  config = {
    home-manager.users.randomcat.imports = [
      ({ config, lib, pkgs, ... }: {
        programs.vim.extraConfig = ''
          autocmd BufNewFile,BufRead /home/randomcat/dev/projects/IdeaProjects/rulekeepor/rules_data/* set ft=yaml textwidth=68
          autocmd BufNewFile,BufRead /home/randomcat/dev/projects/IdeaProjects/rulekeepor/regs_data/* set ft=yaml textwidth=68
        '';
      })
    ];
  };
}
