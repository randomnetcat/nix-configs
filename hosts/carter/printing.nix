{ pkgs, lib, ... }:

{
  config = {
    services.printing.enable = true;

    services.printing.drivers = [
      pkgs.hplipWithPlugin
      pkgs.utsushi
    ];
  };
}
