{ config, lib, pkgs, ... }:

let
  types = lib.types;
  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
  cfg = config.randomcat.services.backups;
  targetParent = cfg.target.parentDataset;

  childPerms = [
    "create"
    "mount"
    "bookmark"
    "hold"
    "receive"
    "snapshot"
  ];
in
{
  imports = [
    ./prune.nix
  ];

  options = {
    randomcat.services.backups.target = {
      enable = lib.mkEnableOption "Backups destination";

      parentDataset = lib.mkOption {
        type = types.str;
        description = "The parent dataset under which to store backups from other hosts";
      };

      acceptSources = lib.mkOption {
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
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

            childDataset = lib.mkOption {
              type = types.str;
              description = "The name of the child dataset to grant access to";
            };

            fullDataset = lib.mkOption {
              type = types.str;
              description = "The full name of the destination dataset";
              internal = true;
            };

            syncoidTag = lib.mkOption {
              type = types.str;
              description = "The tag that syncoid uses in sync snapshots for this source";
            };
          };

          config = {
            name = lib.mkDefault name;
            user = lib.mkDefault ("sync-" + config.name);
            childDataset = lib.mkDefault config.name;
            fullDataset = "${targetParent}/${config.childDataset}";
            syncoidTag = lib.mkDefault config.name;
          };
        }));

        default = { };
        description = "Descriptions of sources that this destination host should be prepared to accept backups from";
      };
    };
  };

  config =
    let
      mkUser = sourceCfg: lib.mkIf (sourceCfg.user == "sync-${sourceCfg.name}") {
        isSystemUser = true;
        useDefaultShell = true;
        group = sourceCfg.user;
        openssh.authorizedKeys.keys = lib.mkIf (sourceCfg.sshKey != null) [ sourceCfg.sshKey ];

        # syncoid wants these packages
        packages = [
          pkgs.mbuffer
          pkgs.lzop
        ];
      };

      mkGroup = sourceCfg: lib.mkIf (sourceCfg.user == "sync-${sourceCfg.name}") { };

      sourcesList = lib.attrValues cfg.target.acceptSources;
    in
    lib.mkIf cfg.target.enable {
      randomcat.services.zfs.datasets = lib.mkMerge (map
        (sourceCfg: {
          "${sourceCfg.fullDataset}" = {
            mountpoint = "none";
            zfsPermissions.users."${sourceCfg.user}" = childPerms;
          };
        })
        sourcesList);

      randomcat.services.backups.prune = {
        enable = true;

        datasets = lib.mkMerge (map
          (sourceCfg: {
            "${sourceCfg.fullDataset}".syncoidTags = [ sourceCfg.syncoidTag ];
          })
          sourcesList);
      };

      users.users = lib.mkMerge (map
        (sourceCfg: {
          "${sourceCfg.user}" = mkUser sourceCfg;
        })
        sourcesList);

      users.groups = lib.mkMerge (map
        (sourceCfg: {
          "${sourceCfg.user}" = mkGroup sourceCfg;
        })
        sourcesList);
    };
}
