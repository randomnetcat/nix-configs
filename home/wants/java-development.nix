{ config, lib, pkgs, ... }:

{
  imports = [
    ./general-development.nix
  ];

  options = { };

  config =
    let
      jdks = {
        "11" = pkgs.jdk11;
        "17" = pkgs.jdk17;
        "21" = pkgs.jdk21;

        current = pkgs.jdk21;
      };
    in
    {
      home.file = lib.mkMerge (lib.mapAttrsToList
        (name: pkg: {
          "dev/toolchains/java/jdks/${name}".source = pkg.home;
        })
        jdks);

      programs.java.enable = true;
      programs.java.package = jdks.current;

      programs.gradle = {
        enable = true;

        package = pkgs.gradle.override {
          javaToolchains = map (p: p.home) (lib.attrValues jdks);
        };

        # Add settings to ensure that Gradle wrappers are also configured to
        # find these JVMs.
        settings = {
          "org.gradle.java.installations.paths" = lib.concatStringsSep "," (map (jdk: jdk.home) (lib.attrValues jdks));
        };
      };

      home.packages = [
        pkgs.jetbrains.idea-community
      ];
    };
}
