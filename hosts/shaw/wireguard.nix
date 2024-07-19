{ config, lib, pkgs, ... }:

{
  imports = [
    ../../sys/impl/fs-keys.nix
  ];

  config = {
    networking = {
      firewall.allowedUDPPorts = [ config.networking.wireguard.interfaces.wg0.listenPort ];

      wireguard.interfaces.wg0 = {
        ips = [ "10.127.1.2/24" "fd70:81ca:0f8f:1::2/64" ];
        listenPort = 51820;
        privateKeyFile = "/run/keys/wireguard-birdsong-key";
        peers = [
          {
            publicKey = "birdLVh8roeZpcVo308Ums4l/aibhAxbi7MBsglkJyA=";
            allowedIPs = [ "10.127.1.0/24" "fd70:81ca:0f8f:1::/64" ];
            endpoint = "birdsong.network:51820";
            # persistentKeepalive = 23;
          }
        ];
      };
    };

    randomcat.services.fs-keys.wireguard-birdsong-creds = {
      requiredBy = [ "wireguard-wg0.service" ];
      before = [ "wireguard-wg0.service" ];

      keys.wireguard-birdsong-key = {
        source.encrypted.path = ./secrets/wireguard-birdsong-key;
      };
    };
  };
}
