{ config, pkgs, ... }:

{
  imports = [
    ./mounts/feature/gaming.nix
  ];

  config = {
    programs.steam.enable = true;
    services.joycond.enable = true;
  };
}
