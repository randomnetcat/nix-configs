{ config, lib, pkgs, ... }:

let
  tailscaleIP = "100.103.37.71";
in
{
  config = {
    services.openssh = {
      enable = true;
      openFirewall = false;

      listenAddresses = [
        {
          addr = tailscaleIP;
          port = 2222;
        }
      ];

      settings = {
        PermitRootLogin = "no";
        AllowUsers = [ "sync-*" ];
      };
    };

    systemd.services.sshd = {
      wants = [ "tailscale-autoconnect.service" ];
      after = [ "tailscale-autoconnect.service" ];
    };
  };
}
