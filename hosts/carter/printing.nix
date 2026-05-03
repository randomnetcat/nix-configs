{ pkgs, lib, ... }:

{
  config = {
    services.printing.enable = true;

    services.printing.drivers = [
      pkgs.hplipWithPlugin
      pkgs.utsushi
      pkgs.epson-escpr
      pkgs.epson-escpr2
      pkgs.epsonscan2
    ];

    hardware.sane = {
      enable = true;

      extraBackends = [
        pkgs.epsonscan2
        pkgs.epkowa
        pkgs.utsushi
      ];

      # Add apartment Epson printer.
      netConf = ''
        192.168.3.10
      '';
    };

    services.udev.packages = [
      pkgs.utsushi
    ];

    users.users.randomcat.extraGroups = [
      "scanner"
      "lp"
    ];

    # CUPS trying to read fingerprints causes it to freeze until a fingerprint
    # is provided, even if a password is provided by HTTP Basic auth. So,
    # disable it (and disable U2F authentication because it probably has a
    # similar problem, though I haven't tested it).
    security.pam.services.cups = {
      fprintAuth = false;
      u2fAuth = false;
    };
  };
}
