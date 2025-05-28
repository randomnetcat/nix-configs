{ config, lib, pkgs, ... }:

let
  types = lib.types;
  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
  cfg = config.randomcat.services.backups.target;

  movementType = types.submodule ({ config, name, ... }: {
    options = {
      sourceName = lib.mkOption {
        type = types.str;
        description = "Friendly name of the host to pull data from.";
        default = name;
      };

      sourceUser = lib.mkOption {
        type = types.str;
        description = "Name of the user to login to the source as.";
        default = "sync-${config.networking.hostName}";
      };

      sourceHost = lib.mkOption {
        type = types.str;
        description = "DNS name of the host to backup to";
        default = config.sourceName;
      };

      sourcePort = lib.mkOption {
        type = types.port;
        description = "Port to connect to the target host on.";
        default = 22;
      };

      sourceDataset = lib.mkOption {
        type = types.str;
        description = "Name of the dataset to backup from (on the source).";
      };

      targetGroupDataset = lib.mkOption {
        type = types.str;
        description = ''
          Each movement is stored in a dataset constructed as follows: <parent>/<group>/<child>. This allows controlling permissions for each <group> separately while still allowing syncoid to create the <child> dataset itself (which it insists on doing).
        
          This option controls the <group> portion.
        '';
      };

      targetChildDataset = lib.mkOption {
        type = types.str;
        description = ''
          Each movement is stored in a dataset constructed as follows: <parent>/<group>/<child>. This allows controlling permissions for each <group> separately while still allowing syncoid to create the <child> dataset itself (which it insists on doing).
        
          This option controls the <child> portion.
        '';
      };

      targetFullDataset = lib.mkOption {
        type = types.str;
        description = "The full (absolute) name of the dataset to grant access to (on the target).";
      };

      syncoidTag = lib.mkOption {
        type = types.str;
        description = "The syncoid identifier to use";
        default = name;
      };
    };

    config = {
      targetFullDataset = "${cfg.parentDataset}/${config.targetGroupDataset}/${config.targetChildDataset}";
    };
  });
in
{
  imports = [
    ./prune.nix
  ];

  options = {
    randomcat.services.backups.target = {
      enable = lib.mkEnableOption "Backups destination";

      encryptedSyncKey = lib.mkOption {
        type = types.path;
        description = "Path to systemd-encrypted credential (with name sync-key) containing SSH key used to login to targets";
      };

      parentDataset = lib.mkOption {
        type = types.str;
        description = "The parent dataset under which to store backups from other hosts";
      };

      movements = lib.mkOption {
        type = types.listOf movementType;
        default = [ ];
        description = "Descriptions of sources that this destination host should be prepared to accept backups from";
      };
    };
  };

  config =
    let
      targetPerms = [
        "create"
        "mount"
        "bookmark"
        "hold"
        "receive:append"
        "snapshot"
      ];

      commandNameFor = movement: "${movement.targetGroupDataset}-${movement.targetChildDataset}";
    in
    lib.mkIf cfg.enable {
      randomcat.services.zfs.datasets = lib.mkMerge ([{
        "${cfg.parentDataset}" = {
          mountpoint = "none";
        };
      }] ++ (map
        (group: {
          "${cfg.parentDataset}/${group}" = {
            mountpoint = "none";
          };
        })
        (lib.unique (map (movement: movement.targetGroupDataset) cfg.movements))));

      randomcat.services.backups.prune = {
        enable = true;

        datasets = lib.mkMerge (map
          (movement: {
            "${movement.targetFullDataset}".syncoidTags = [ movement.syncoidTag ];
          })
          cfg.movements);
      };

      services.syncoid = {
        enable = true;

        interval = "*-*-* 06:00:00 UTC";

        commands = lib.mkMerge (lib.imap0
          (i: m:
            let commandName = commandNameFor m; in {
              ${commandName} = {
                source = "${m.sourceUser}@${m.sourceHost}:${m.sourceDataset}";
                target = m.targetFullDataset;
                recursive = true;
                localTargetAllow = targetPerms;

                # u -> don't mount datasets
                # x [property] -> ignore property from stream
                # * recordsize: set for specific access patterns; we don't need to preserve them
                # * compression: compression is a local policy
                # * encryption: encryption is a local policy
                recvOptions = "ux recordsize x compression x encryption";

                # Load the SSH key as a systemd credential. LoadCredentialEncrypted is set below.
                sshKey = "/run/credentials/syncoid-${commandName}.service/sync-key";

                extraArgs = [
                  "--no-privilege-elevation"
                  "--keep-sync-snap"
                  "--no-rollback"
                  "--sshport=${toString m.sourcePort}"
                  "--identifier=${m.syncoidTag}"
                ];
              };
            })
          cfg.movements);
      };

      systemd.services = lib.mkMerge (lib.imap0
        (i: m: {
          "syncoid-${commandNameFor m}" = {
            unitConfig = {
              StartLimitBurst = 2;
              StartLimitIntervalSec = "1 hour";
            };

            serviceConfig = {
              Restart = "on-failure";
              RestartSec = "1 hour";
              TimeoutStartSec = "2 hours";

              LoadCredentialEncrypted = "sync-key:${cfg.encryptedSyncKey}";
            };
          };
        })
        cfg.movements);

      systemd.timers = lib.mkMerge (lib.imap0
        (i: m: {
          "syncoid-${commandNameFor m}" = {
            timerConfig = {
              Persistent = true;
              RandomizedDelaySec = "30m";
            };
          };
        })
        cfg.movements);
    };
}
