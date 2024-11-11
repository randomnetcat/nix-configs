{ config, lib, pkgs, ... }:

{
  imports = [
    ./general-development.nix
  ];

  options = {
  };

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
      home.file = lib.mkMerge (lib.mapAttrsToList (name: pkg: {
        "dev/toolchains/java/jdks/${name}".source = pkg.home;
      }) jdks);

      programs.java.enable = true;
      programs.java.package = jdks.current;

      home.packages = [
        pkgs.jetbrains.idea-ultimate
        (pkgs.gradle.override {
          javaToolchains = map (p: p.home) (lib.attrValues jdks);
        })
      ];
    };
}
