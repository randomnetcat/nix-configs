{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.home.dev-jdks-dir;
  jdksOptions = { name, pkgs, ... }:
  {
    options = {
      package = lib.mkOption {
        type = lib.types.package;
        description = ''JDK package to install.'';
      };
    };
  };
in
{
  imports = [
  ];

  options = {
    randomcat.home.dev-jdks-dir = {
      enable = lib.mkEnableOption "~/dev dir";

      jdks = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule jdksOptions);
        description = ''Attr set of JDKs to install by name.'';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge ([
      {
        "dev/jdks/.keep".text = "";
      }
    ] ++ (lib.mapAttrsToList (name: value: { "dev/jdks/${name}".source = "${value.package.home}"; }) cfg.jdks));
  };
}
