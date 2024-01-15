{ config, pkgs, ... }:

{
  imports = [
    # ./mounts/feature/gaming.nix
  ];

  options = {
  };

  config = {
    programs.steam.enable = true;
    services.joycond.enable = true;
  };
}
