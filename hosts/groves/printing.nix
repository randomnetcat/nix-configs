{ pkgs, lib, ... }:

{
  config = {
    services.printing.enable = false;

    services.printing.drivers = lib.mkMerge [
      (lib.mkIf (!(lib.hasPrefix "3.23." pkgs.hplipWithPlugin.version)) [
        pkgs.hplipWithPlugin
      ])

      # Apartment Epson ET02760
      [
        pkgs.utsushi
      ]
    ];
  };
}
