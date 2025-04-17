{ config, lib, pkgs, ... }:

{
  config = {
    home-manager.users.randomcat.imports = [
      (
        let
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

              "php.debug.executablePath" = "${php}/bin/php";
              "php.validate.executablePath" = "${php}/bin/php";

              "html.format.wrapAttributes" = "force-expand-multiline";

              "[vue]" = {
                "editor.defaultFormatter" = "Vue.volar";
              };
            };
          };
        }
      )
    ];
  };
}
