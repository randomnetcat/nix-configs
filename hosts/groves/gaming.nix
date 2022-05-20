{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    programs.steam.enable = true;
    services.joycond.enable = true;
  };
}
