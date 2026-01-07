{ config, lib, ... }:

let
  networkCfg = config.randomcat.network;
  cfg = networkCfg.backups;

  types = lib.types;

  sourceType = types.submodule { };

  targetType = types.submodule ({
    options = {
      syncKey = lib.mkOption {
        type = types.nullOr types.str;
        description = "The public SSH key to be used for backups";
        default = null;
      };
    };
  });

  movementType = types.submodule ({ config, ... }: {
    options = {
      sourceHost = lib.mkOption {
        type = types.str;
        description = "The name of the host to backup from";
      };

      targetHost = lib.mkOption {
        type = types.str;
        description = "The name of the host to backup to";
      };

      ignoreFailure = lib.mkOption {
        type = types.bool;
        description = "Whether to ignore failures that occur during this backup.";
        default = networkCfg.hosts."${config.sourceHost}".isPortable;
      };

      datasets = lib.mkOption {
        type = types.listOf (types.submodule {
          options = {
            source = lib.mkOption {
              type = types.str;
              description = ''
                The name of the parent dataset to copy from on the source. Will
                have datasetName appended to determine the full dataset.
              '';
            };

            target = lib.mkOption {
              type = types.str;
              description = ''
                The name of the parent dataset to copy to on the target. Will
                have datasetName appended to determine the full dataset.
              '';
            };

            datasetName = lib.mkOption {
              type = types.str;
              description = ''
                The name of the child dataset to copy on both the source and
                the target.
              '';
            };
          };
        });

        description = "The datasets to copy from the source to the target";
      };
    };
  });

  hostNameAssertions = lib.concatMap
    (opt: map
      (name: {
        assertion = networkCfg.hosts ? "${name}";
        message = "The backup host ${name} must exist in the network configuration.";
      })
      (lib.attrNames cfg."${opt}")) [ "sources" "targets" ];

  movementAssertions = lib.concatMap
    (movement: [
      {
        assertion = cfg.sources ? "${movement.sourceHost}";
        message = "Host ${movement.sourceHost} is used as a movement sourceHost but is not defined as a source.";
      }

      {
        assertion = cfg.targets ? "${movement.targetHost}";
        message = "Host ${movement.targetHost} is used as a movement targetHost but is not defined as a target.";
      }
    ])
    cfg.movements;
in
{
  imports = [
    ./hosts.nix
  ];

  options = {
    randomcat.network = {
      backups = {
        sources = lib.mkOption {
          type = types.attrsOf sourceType;
          default = { };
        };

        targets = lib.mkOption {
          type = types.attrsOf targetType;
          default = { };
        };

        movements = lib.mkOption {
          type = types.listOf movementType;
          default = [ ];
        };
      };
    };
  };

  config = {
    assertions = hostNameAssertions ++ movementAssertions;
  };
}
