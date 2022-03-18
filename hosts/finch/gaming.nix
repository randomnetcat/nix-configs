{ config, pkgs, ... }:

{
  imports = [
    ./mounts/feature/games.nix
  ];

  options = {
  };

  config = {
    programs.steam.enable = true;
  };
}
