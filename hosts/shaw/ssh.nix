{ config, lib, pkgs, ... }:

let
  birdsongIPs = let host = config.birdsong.hosts.shaw; in [ host.ipv4 host.ipv6 ];
in
{
  config = {
    services.openssh = {
      enable = true;
      openFirewall = false;

      listenAddresses = map
        (ip: {
          addr = "[${ip}]";
          port = 22;
        })
        birdsongIPs;

      settings = {
        PermitRootLogin = "no";
        AuthenticationMethods = "publickey";
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
      };
    };

    networking.firewall.interfaces.wg-birdsong.allowedTCPPorts = [ 22 ];

    systemd.services.sshd = {
      wants = [ "wireguard-wg-birdsong.service" ];
      after = [ "wireguard-wg-birdsong.service" ];
    };
  };
}
