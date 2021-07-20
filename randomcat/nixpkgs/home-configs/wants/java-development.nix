{ config, lib, pkgs, ... }:

{
  imports = [
    ../detail/dev-dir.nix
  ];

  options = {
  };

  config = {
    randomcat.home.dev-dir.enable = true;

    home.packages = [
      pkgs.jetbrains.idea-ultimate
      pkgs.jdk
      pkgs.gradle
    ];

    home.activation = {
      generateStaticJdk = lib.hm.dag.entryAfter ["writeBoundary" "createDevDir"] ''
        $DRY_RUN_CMD ln -fs $VERBOSE_ARG -T -- "${pkgs.jdk}" "/nix/var/nix/gcroots/per-user/$USER/dev_jdk"
        $DRY_RUN_CMD ln -fs $VERBOSE_ARG -T -- "${pkgs.jdk.home}" "$HOME/dev/nix_jdk"
      '';
    };
  };
}
