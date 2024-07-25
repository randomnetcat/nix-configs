{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../../sys/impl/fs-keys.nix
    ../../sys/impl/zfs-create.nix
  ];

  config = {
    birdsong.peering = {
      enable = true;
      interface = "wg-birdsong";
      openPorts = true;
      privateKeyFile = "/run/keys/wireguard-birdsong-key";
      persistentKeepalive = 23;
    };

    randomcat.services.fs-keys.wireguard-birdsong-creds = {
      requiredBy = [ "wireguard-wg-birdsong.service" ];
      before = [ "wireguard-wg-birdsong.service" ];

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
