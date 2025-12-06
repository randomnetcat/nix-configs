{ config, lib, pkgs, ... }:

{
  config = {
    services.sanoid = {
      enable = true;
      interval = "*:0/15";
      extraArgs = [ "--verbose" "--debug" ];
    };
  };
}
