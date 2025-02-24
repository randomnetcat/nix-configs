{ config, pkgs, lib, ... }:

{
  config = {
    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };

    # Per https://wiki.nixos.org/wiki/Fingerprint_scanner
    systemd.services.fprintd = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.type = "simple";
    };

    services.fprintd.enable = true;
  };
}
