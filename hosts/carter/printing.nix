{ pkgs, lib, ... }:

{
  config = {
    services.printing.enable = true;

    services.printing.drivers = [
      pkgs.hplipWithPlugin
      pkgs.utsushi
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
