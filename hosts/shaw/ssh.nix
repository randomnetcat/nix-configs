{ config, lib, pkgs, ... }:

{
  config = {
    services.openssh = {
      enable = true;
      openFirewall = false;

      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 22;
        }

        {
          addr = "[::]";
          port = 22;
        }
      ];

      settings = {
        PermitRootLogin = "no";
        AuthenticationMethods = "publickey";
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
      };
    };

    networking.firewall.allowedTCPPorts = [ 22 ];

    systemd.services.sshd = {
      wants = [ "wireguard-wg-birdsong.service" ];
      after = [ "wireguard-wg-birdsong.service" ];
    };

    users.users.randomcat = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHagOaeTR+/7FL9sErciMw30cmV/VW8HU7J3ZFU5nj9"
      ];
    };
  };
}
