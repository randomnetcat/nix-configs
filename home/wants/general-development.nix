{ config, pkgs, lib, ... }:

{
  imports = [
    ../detail/version-control-common.nix
  ];

  config = {
    home.file."dev/.keep".text = "";

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
  };
}
