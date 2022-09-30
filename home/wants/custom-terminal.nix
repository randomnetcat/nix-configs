{ config, lib, pkgs, ... }:

{
  imports = [
    ../detail/cmdline/vim.nix
  ];

  options = {};

  config = {
    home.packages = [
      pkgs.killall
      pkgs.file
    ];

    programs.ssh.enable = true;
    programs.jq.enable = true;

    programs.bash = {
      enable = true;

      # Source home-manager session variables into bash
      initExtra = ''
        if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; fi
        if [ -e "/etc/profiles/per-user/randomcat/etc/profile.d/hm-session-vars.sh" ]; then . "/etc/profiles/per-user/randomcat/etc/profile.d/hm-session-vars.sh"; fi
      '';

      shellAliases = {
        ls = "ls -l";
      };
    };

    home.sessionVariables = let editorProgram = "vim"; in {
      EDITOR = editorProgram;
      VISUAL = editorProgram;
    };
  };
}
