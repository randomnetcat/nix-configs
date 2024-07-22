{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.backups.source;

  types = lib.types;

  movementType = types.submodule ({ config, ... }: {
    options = {
      targetName = lib.mkOption {
        type = types.str;
        description = "Friendly name of the host to backup to";
      };

      targetHost = lib.mkOption {
        type = types.str;
        description = "DNS name of the host to backup to";
        default = config.targetName;
      };

      targetUser = lib.mkOption {
        type = types.str;
        description = "User to login to the target host with";
        default = "sync-${config.networking.hostName}";
      };

      targetPort = lib.mkOption {
        type = types.port;
        description = "Port to connect to the target host on";
        default = 2222;
      };

      sourceDataset = lib.mkOption {
        type = types.str;
        description = "Name of the dataset to backup from (on the source)";
      };

      targetDataset = lib.mkOption {
        type = types.str;
        description = "Name of the dataset to backup to (on the target)";
      };
    };
  });
in
{
  imports = [
    ../../impl/fs-keys.nix
  ];

  options = {
    randomcat.services.backups.source = {
      enable = lib.mkEnableOption "Backups source";

      encryptedSyncKey = lib.mkOption {
        type = types.path;
        description = "Path to systemd-encrypted credential (with name sync-key) containing SSH key used to login to targets";
      };

      movements = lib.mkOption {
        type = types.listOf movementType;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncoid = {
      enable = true;

      interval = "*-*-* 06:00:00 UTC";

      commands = lib.mkMerge (lib.imap0 (i: m: {
        "randomcat-${toString i}-${m.targetName}" = {
          source = m.sourceDataset;
          target = "${m.targetUser}@${m.targetHost}:${m.targetDataset}";
          recursive = true;
          sshKey = "/run/keys/sync-key";
          localSourceAllow = [ "bookmark" "hold" "send" "snapshot" "destroy" "mount" ];
          
          extraArgs = [
            "--no-privilege-elevation"
            "--keep-sync-snap"
            "--no-rollback"
            "--sshport=${toString m.targetPort}"
          ];
        };
      }) cfg.movements);
    };

    systemd.services = lib.mkMerge (lib.imap0 (i: m: {
      "syncoid-randomcat-${toString i}-${m.targetName}" = {
        requires = [ "sync-creds.service" ];
        after = [ "sync-creds.service" ];

        unitConfig = {
          StartLimitBurst = 3;
          StartLimitIntervalSec = "12 hours";
        };

        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "15min";
          TimeoutStartSec = "2 hours";
        };
      };
    }) cfg.movements);

    users.users.syncoid.extraGroups = [ "keys" ];

    randomcat.services.fs-keys.sync-creds = {
      keys.sync-key = {
        user = config.users.users.syncoid.name;
        source.encrypted.path = cfg.encryptedSyncKey;
      };
    };
  };
}
