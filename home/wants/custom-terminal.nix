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
      pkgs.dnsutils
    ];

    programs.bat.enable = true;
    programs.htop.enable = true;
    programs.jq.enable = true;
    programs.ripgrep.enable = true;
    programs.ssh.enable = true;

    programs.eza.enable = true;
    programs.eza.extraOptions = [ "--group" ];

    programs.bash = {
      enable = true;

      historySize = -1;
      historyFileSize = -1;

      # Source home-manager session variables into bash
      initExtra = ''
        if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; fi
        if [ -e "/etc/profiles/per-user/${config.home.username}/etc/profile.d/hm-session-vars.sh" ]; then . "/etc/profiles/per-user/randomcat/etc/profile.d/hm-session-vars.sh"; fi
      '';

      shellAliases = {
        ls = "eza -l";
      };
    };

    home.sessionVariables = let editorProgram = "vim"; in {
      EDITOR = editorProgram;
      VISUAL = editorProgram;
    };
  };
}
