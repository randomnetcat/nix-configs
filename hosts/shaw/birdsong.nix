{ config, lib, pkgs, ... }:

{
  imports = [
    ../../sys/impl/fs-keys.nix
    ../../sys/impl/zfs-create.nix
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

    randomcat.services.zfs.create.datasets = {
      "nas_oabrke/data/users" = {
        mountpoint = "none";
      };

      "nas_oabrke/data/users/qenya" = {
        zfsOptions = {
          # Don't use a Nix-managed mountpoint in order to allow inheritance.
          mountpoint = "/home/qenya/data";
          quota = "2TiB";
        };

        zfsPermissions.users."${config.users.users.qenya.name}" = [
          "bookmark"
          "clone"
          "create"
          "destroy"
          "diff"
          "hold"
          "mount"
          "promote"
          "receive"
          "rename"
          "rollback"
          "send"
          "snapshot"
        ];
      };
    };

    users.users.qenya = {
      isNormalUser = true;
      group = config.users.groups.qenya.name;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJEmkV9arotms79lJPsLHkdzAac4eu3pYS08ym0sB/on qenya@tohru"
      ];
    };

    users.groups.qenya = {};
  };
}
