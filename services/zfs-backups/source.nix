{ config, lib, pkgs, ... }:

let
  types = lib.types;

  cfg = config.randomcat.services.backups.source;

  movementType = types.submodule ({ name, config, ... }: {
    options = {
      name = lib.mkOption {
        type = types.str;
        description = "The name of the host";
      };

      user = lib.mkOption {
        type = types.str;
        description = "The name of the username to accept for backups";
      };

      authorizedKeys = lib.mkOption {
        type = types.listOf types.str;
        description = "The SSH key to add to the user";
        default = [ ];
      };

      sourceDatasets = lib.mkOption {
        type = types.listOf types.str;
        description = "The name of the dataset to grant access to";
      };

      syncoidTag = lib.mkOption {
        type = types.str;
        description = "The tag that syncoid uses in sync snapshots for this source";
      };

      enableSyncSnapshots = (lib.mkEnableOption "syncoid sync snapshots") // {
        default = true;
      };
    };

    config = {
      name = lib.mkDefault name;
      user = lib.mkDefault ("backup-" + config.name);
      syncoidTag = lib.mkDefault config.name;
    };
  });
in
{
  imports = [
    ./prune.nix
  ];

  options = {
    randomcat.services.backups.source = {
      enable = lib.mkEnableOption "Backups source";

      acceptTargets = lib.mkOption {
        type = types.attrsOf movementType;
        description = "Descriptions of backup targets that this source host should be prepared to accept connections from.";
        default = { };
      };
    };
  };

  config =
    let
      targetsList = lib.attrValues cfg.acceptTargets;

      mkUser = targetCfg: lib.mkIf (targetCfg.user == "backup-${targetCfg.name}") {
        isSystemUser = true;
        useDefaultShell = true;
        group = targetCfg.user;

        # syncoid wants these packages
        packages = [
          pkgs.mbuffer
          pkgs.lzop
        ];
      };

      mkGroup = targetCfg: lib.mkIf (targetCfg.user == "backup-${targetCfg.name}") { };
    in
    lib.mkIf cfg.enable {
      users.users = lib.mkMerge (map
        (targetCfg: {
          "${targetCfg.user}" = lib.mkMerge [
            (mkUser targetCfg)

            # Ensure that we always set authorizedKeys, even if we don't create the rest of the user.
            {
              openssh.authorizedKeys.keys = targetCfg.authorizedKeys;
            }
          ];
        })
        targetsList);

      users.groups = lib.mkMerge (map
        (targetCfg: {
          "${targetCfg.user}" = mkGroup targetCfg;
        })
        targetsList);

      randomcat.services.zfs.datasets = lib.mkMerge (lib.concatMap
        (targetCfg: map
          (dataset: {
            "${dataset}".zfsPermissions.users."${targetCfg.user}" = [
              "hold"
              "release"
              "send"
            ] ++ lib.optionals targetCfg.enableSyncSnapshots [
              "snapshot"
              "bookmark"
            ];
          })
          (targetCfg.sourceDatasets))
        targetsList);

      randomcat.services.backups.prune = {
        enable = true;

        datasets = lib.mkMerge (lib.concatMap
          (targetCfg: map
            (dataset: {
              "${dataset}".syncoidTags = [ targetCfg.syncoidTag ];
            })
            (targetCfg.sourceDatasets))
          (lib.filter (targetCfg: targetCfg.enableSyncSnapshots) (lib.attrValues cfg.acceptTargets)));
      };
    };
}
