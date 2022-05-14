{ config, pkgs, lib, ... }:

{
  config = {
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.pcscd.enable = true;

    security.pam.yubico = {
      enable = true;
      debug = true;
      mode = "challenge-response";
    };
  };
}
