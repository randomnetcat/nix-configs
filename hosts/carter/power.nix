{ config, lib, pkgs, ... }:

{
  config = {
    services.tlp.enable = false;
    services.power-profiles-daemon.enable = true;
  };
}
