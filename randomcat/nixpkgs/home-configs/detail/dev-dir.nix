{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.home.dev-dir;
in
{
  imports = [
  ];

  options = {
    randomcat.home.dev-dir = {
      enable = lib.mkEnableOption "~/dev dir";
    };
  };

  config = {
    home.file."dev/.keep" = lib.mkIf cfg.enable {
      text = "";
    };
  };
}
