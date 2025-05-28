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

      sshKey = lib.mkOption {
        type = types.nullOr types.str;
        description = "The SSH key to add to the user";
        default = null;
      };

      sourceDatasets = lib.mkOption {
        type = types.listOf types.str;
        description = "The name of the dataset to grant access to";
      };

      syncoidTag = lib.mkOption {
        type = types.str;
        description = "The tag that syncoid uses in sync snapshots for this source";
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

      targetPerms = [
        "snapshot"
        "bookmark"
        "hold"
        "send"
      ];

      mkUser = targetCfg: lib.mkIf (targetCfg.user == "backup-${targetCfg.name}") {
        isSystemUser = true;
        useDefaultShell = true;
        group = targetCfg.user;
        openssh.authorizedKeys.keys = lib.mkIf (targetCfg.sshKey != null) [ targetCfg.sshKey ];

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
          "${targetCfg.user}" = mkUser targetCfg;
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
            "${dataset}".zfsPermissions.users."${targetCfg.user}" = targetPerms;
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
          (lib.attrValues cfg.acceptTargets));
      };
    };
}
