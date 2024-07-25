{ config, lib, pkgs, ... }:

let
  tailscaleIP = "100.103.37.71";
  birdsongIPs = let host = config.birdsong.hosts.shaw; in [ host.ipv4 host.ipv6 ];
in
{
  config = {
    services.openssh = {
      enable = true;
      openFirewall = false;

      listenAddresses = [{
        addr = tailscaleIP;
        port = 2222;
      }] ++ (map (ip: {
        addr = "[${ip}]";
        port = 22;
      }) birdsongIPs);

      settings = {
        PermitRootLogin = "no";
        AuthenticationMethods = "publickey";
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
      };
    };

    networking.firewall.interfaces.wg-birdsong.allowedTCPPorts = [ 22 ];

    systemd.services.sshd = {
      wants = [ "tailscale-autoconnect.service" "wireguard-wg-birdsong.service" ];
      after = [ "tailscale-autoconnect.service" "wireguard-wg-birdsong.service" ];
    };
  };
}
