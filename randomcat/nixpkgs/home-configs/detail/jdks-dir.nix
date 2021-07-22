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

  config = {
    home.file."dev/jdks/.keep" = lib.mkIf cfg.enable {
      text = "";
    };

    home.activation =
    let
      jdkGcRootDir = "/nix/var/nix/gcroots/per-user/$USER/linked_jdks";
      dag = lib.hm.dag;
    in
    {
      makeClearJdkGcRootDir = dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD rm -rf $VERBOSE_ARG -- "${jdkGcRootDir}"
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG -- "${jdkGcRootDir}"
      '';

      generateStaticJdks =
        dag.entryAfter
        ["writeBoundary" "makeClearJdkGcRootDir" "linkGeneration"]
        (
          let
            linkJdkScript = name: jdk-pkg: ''
              $DRY_RUN_CMD ln -fs $VERBOSE_ARG -T -- "${jdk-pkg}" "${jdkGcRootDir}/${name}"
              $DRY_RUN_CMD ln -fs $VERBOSE_ARG -T -- "${jdk-pkg.home}" "$HOME/dev/jdks/${name}"
            '';
          in
          lib.concatStrings (lib.mapAttrsToList (name: value: linkJdkScript name value.package) cfg.jdks)
        );
    };
  };
}
