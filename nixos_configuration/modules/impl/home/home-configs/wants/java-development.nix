{ config, lib, pkgs, ... }:

{
  imports = [
    ../detail/dev-dir.nix
    ../detail/jdks-dir.nix
  ];

  options = {
  };

  config = {
    randomcat.home.dev-dir.enable = true;

    randomcat.home.dev-jdks-dir = {
      enable = true;
      jdks = {
        "current" = {
          package = pkgs.jdk;
        };

        "11" = {
          package = pkgs.jdk11;
        };
      };
    };

    home.packages = [
      pkgs.jetbrains.idea-ultimate
      pkgs.jdk
      pkgs.gradle
    ];
  };
}
