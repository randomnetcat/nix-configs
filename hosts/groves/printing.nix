{ pkgs, lib, ... }:

{
  config = {
    services.printing.enable = true;

    services.printing.drivers = lib.mkIf (!(lib.hasPrefix "3.23." pkgs.hplipWithPlugin.version)) [
      pkgs.hplipWithPlugin
    ];
  };
}
