{ config, pkgs, lib, ... }:

{
  config = {
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.pcscd.enable = true;

    security.pam.u2f.enable = true;

    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
  };
}
