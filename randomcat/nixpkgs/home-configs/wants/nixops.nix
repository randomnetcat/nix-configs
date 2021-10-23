{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    home.packages =
      let
        pinnedPkgs = import (builtins.fetchTarball {
          url = "https://github.com/nixos/nixpkgs/archive/65b70fbe4c3a942a266794e28a08147b06ebb6bc.tar.gz";
          sha256 = "0p2kprsxjvrn1m90h91dmjpgxxbbpa9xpwcz5zs2qzcaz279gdkm";
        }) {};
      in
      [
        pinnedPkgs.nixops
      ];
  };
}
