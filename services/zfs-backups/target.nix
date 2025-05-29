{ config, lib, pkgs, ... }:

let
  types = lib.types;
  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
  cfg = config.randomcat.services.backups.target;
  movements = lib.attrValues cfg.movements;

  movementType = types.submodule ({ config, name, ... }: {
    options = {
      name = lib.mkOption {
        type = types.str;
        default = name;
      };

      sourceUser = lib.mkOption {
        type = types.str;
        description = "Name of the user to login to the source as.";
        default = "backup-${config.networking.hostName}";
      };

      sourceHost = lib.mkOption {
        type = types.str;
        description = "DNS name of the host to backup to";
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

      targetParentDataset = lib.mkOption {
        type = types.str;
        description = ''
          Each movement is stored in a dataset constructed as follows:
          <parent>/<child>. This allows creating the <parent> dataset
          separately while still allowing syncoid to create the <child> dataset
          itself (which it inisists on doing).
        
          This option controls the <group> portion.
        '';
      };

      targetChildDataset = lib.mkOption {
        type = types.str;
        description = ''
          Each movement is stored in a dataset constructed as follows:
          <parent>/<child>. This allows creating the <parent> dataset
          separately while still allowing syncoid to create the <child> dataset
          itself (which it inisists on doing).

          This option controls the <child> portion.
        '';
      };

      targetFullDataset = lib.mkOption {
        type = types.str;
        description = "The full (absolute) name of the dataset to grant access to (on the target).";
        readOnly = true;
      };

      syncoidTag = lib.mkOption {
        type = types.str;
        description = "The syncoid identifier to use";
      };

      interval = lib.mkOption {
        type = types.str;
        description = "The interval at which to run the backup for this movement.";
        default = cfg.defaultInterval;
      };

      enableSyncSnapshots = (lib.mkEnableOption "syncoid sync snapshots") // {
        default = true;
      };
    };

    config = {
      targetFullDataset = "${config.targetParentDataset}/${config.targetChildDataset}";
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

      movements = lib.mkOption {
        type = types.attrsOf movementType;
        default = [ ];
        description = "Descriptions of sources that this destination host should be prepared to accept backups from";
      };

      defaultInterval = lib.mkOption {
        type = types.str;
        description = "The interval at which to run backups for movements that are not otherwise configured.";
        default = "*-*-* 06:00:00 UTC";
      };
    };
  };

  config =
    let
      commandNameFor = movement: movement.name;
    in
    lib.mkIf cfg.enable {
      randomcat.services.zfs.datasets = lib.mkMerge (map
        (parentDataset: {
          "${parentDataset}" = {
            mountpoint = "none";
          };
        })
        (lib.unique (map (movement: movement.targetParentDataset) movements)));

      randomcat.services.backups.prune = {
        enable = true;

        datasets = lib.mkMerge (map
          (movement: {
            "${movement.targetFullDataset}".syncoidTags = [ movement.syncoidTag ];
          })
          (lib.filter (m: m.enableSyncSnapshots) movements));
      };

      services.syncoid = {
        enable = true;

        commands = lib.mkMerge (map
          (m:
            let commandName = commandNameFor m; in {
              ${commandName} = {
                source = "${m.sourceUser}@${m.sourceHost}:${m.sourceDataset}";
                target = m.targetFullDataset;
                recursive = true;

                localTargetAllow = [
                  "create"
                  "mount"
                  "receive:append"
                ] ++ lib.optionals m.enableSyncSnapshots [
                  "hold"
                  "bookmark"
                  "snapshot"
                ];

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
                  "--no-rollback"
                  "--sshport=${toString m.sourcePort}"
                  "--identifier=${m.syncoidTag}"
                ] ++ (if m.enableSyncSnapshots then [
                  "--keep-sync-snap"
                ] else [
                  "--no-sync-snap"
                ]);
              };
            })
          movements);
      };

      systemd.services = lib.mkMerge (map
        (m: {
          "syncoid-${commandNameFor m}" = {
            # The syncoid module only accepts a single global interval for some reason. So, we
            # just override it per unit here.
            startAt = lib.mkForce [ m.interval ];

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
        movements);

      systemd.timers = lib.mkMerge (map
        (m: {
          "syncoid-${commandNameFor m}" = {
            timerConfig = {
              Persistent = true;
              RandomizedDelaySec = "30m";
            };
          };
        })
        movements);
    };
}
