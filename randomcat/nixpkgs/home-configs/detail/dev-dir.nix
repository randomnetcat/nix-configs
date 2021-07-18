{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    home.activation = {
      createDevDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir $VERBOSE_ARG -p -- "$HOME/dev"
      '';
    };
  };
}
