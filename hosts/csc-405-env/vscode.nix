{ config, lib, pkgs, ... }:

{
  config = {
    home-manager.users.randomcat.imports = [
      (let
        php = pkgs.php82;
      in
      {
        programs.vscode = {
          enable = true;

          userSettings = {
            "files.autoSave" = "onFocusChange";
            "files.trimTrailingWhitespace" = true;
            "files.insertFinalNewline" = true;
            "files.trimFinalNewlines" = true;

            "files.exclude" = {
              "**/.direnv" = true;
            };

            "editor.insertSpaces" = true;

            "html.format.wrapAttributes" = "force-expand-multiline";
          };
        };
      })
    ];
  };
}
