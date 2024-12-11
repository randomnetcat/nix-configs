{ config, lib, pkgs, inputs, ... }:

let
  usersDataset = "nas_oabrke/data/users";
  qenyaDataset = "${usersDataset}/qenya";
in
{
  imports = [
    ../../sys/impl/fs-keys.nix
  ];

  config = {
    birdsong.peering = {
      enable = true;
      interface = "wg-birdsong";
      openPorts = true;
      privateKeyFile = "/run/keys/wireguard-birdsong-key";
      persistentKeepalive = 23;
    };

    users.users.systemd-network.extraGroups = [
      config.users.groups.keys.name
    ];

    randomcat.services.fs-keys.wireguard-birdsong-creds = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-pre.target" ];
      before = [ "network-pre.target" ];

      keys.wireguard-birdsong-key = {
        source.encrypted.path = ./secrets/wireguard-birdsong-key;

        user = config.users.users.root.name;
        group = config.users.groups.systemd-network.name;
        mode = "0640";
      };
    };

    randomcat.services.zfs.datasets = {
      "${usersDataset}" = {
        mountpoint = "none";
      };

      "${qenyaDataset}" = {
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
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJEmkV9arotms79lJPsLHkdzAac4eu3pYS08ym0sB/on qenya@tohru"
      ];

      extraGroups = [
        # Temporary? I locked myself out. Good job me.
        "wheel"
      ];
    };

    users.groups.qenya = {};

    programs.zsh.enable = true;

    home-manager.users.qenya.imports = [
      inputs.qenyaNixfiles.homeManagerModules."qenya"
      inputs.qenyaNixfiles.homeManagerModules."qenya@shaw"
    ];

    nix.settings.allowed-users = [
      config.users.users.qenya.name
    ];

    security.sudo = {
      # qenya is not in wheel
      execWheelOnly = false;

      extraRules = [
        {
          users = [ "qenya" ];
          commands = [
            {
              # This is safe because qenya does not have the permission to set
              # the mountpoint property on child datasets they create.
              command = "/run/current-system/sw/bin/zfs mount -R ${qenyaDataset}";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

    # Syncthing. Note that ports are one greater than defaults.
    networking.firewall = {
      allowedTCPPorts = [ 8385 22001 ];
      allowedUDPPorts = [ 21028 22001 ];
    };
  };
}
