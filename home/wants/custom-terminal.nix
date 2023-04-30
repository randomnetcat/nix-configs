{ config, lib, pkgs, ... }:

{
  imports = [
    ../detail/cmdline/vim.nix
  ];

  options = {};

  config = {
    home.packages = [
      pkgs.file
      pkgs.fx
      pkgs.glow
      pkgs.hexyl
      pkgs.killall
      pkgs.sl
    ];

    programs.bat.enable = true;
    programs.exa.enable = true;
    programs.git.diff-so-fancy.enable = true;
    programs.htop.enable = true;
    programs.jq.enable = true;
    programs.ssh.enable = true;

    programs.bash = {
      enable = true;

      # Source home-manager session variables into bash
      initExtra = ''
        if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; fi
        if [ -e "/etc/profiles/per-user/${config.home.username}/etc/profile.d/hm-session-vars.sh" ]; then . "/etc/profiles/per-user/randomcat/etc/profile.d/hm-session-vars.sh"; fi
      '';

      shellAliases = {
        ls = "exa -l";
      };
    };

    home.sessionVariables = let editorProgram = "vim"; in {
      EDITOR = editorProgram;
      VISUAL = editorProgram;
    };
  };
}
