{ config, lib, ... }:

let
  networkCfg = config.randomcat.network;
  cfg = networkCfg.backups;

  types = lib.types;

  sourceType = types.submodule ({
    options = {
      syncKey = lib.mkOption {
        type = types.nullOr types.str;
        description = "The public SSH key to be used for backups";
        default = null;
      };
    };
  });

  targetType = types.submodule ({
    options = {
      backupsDataset = lib.mkOption {
        type = types.str;
        description = ''
          The dataset to store backups in. Sub-datasets for each source host will be created.

          For example, if this is pool/backups, and host foo backups to this, the dataset
          pool/backups/foo will be created.
        '';
      };
    };
  });

  movementType = types.submodule ({
    options = {
      sourceHost = lib.mkOption {
        type = types.str;
        description = "The name of the host to backup from";
      };

      targetHost = lib.mkOption {
        type = types.str;
        description = "The name of the host to backup to";
      };

      datasets = lib.mkOption {
        type = types.listOf (types.submodule {
          options = {
            source = lib.mkOption {
              type = types.str;
              description = "The name of the dataset to copy from";
            };

            target = lib.mkOption {
              type = types.str;
              description = ''
                The name of the dataset under the target's backupsDataset to
                copy to.

                For instance, if the target's backup dataset is pool/backups,
                the source's name is source, and the target dataset is foo, the
                source dataset will be copied to pool/backups/source/foo.
              '';
            };
          };
        });

        description = "The datasets to copy from the source to the target";
      };
    };
  });

  hostNameAssertions = lib.concatMap (opt: map (name: {
    assertion = networkCfg.hosts ? "${name}";
    message = "The backup host ${name} must exist in the network configuration.";
  }) (lib.attrNames cfg."${opt}")) [ "sources" "targets" ];

  movementAssertions = lib.concatMap (movement: [
    {
      assertion = cfg.sources ? "${movement.sourceHost}";
      message = "Host ${movement.sourceHost} is used as a movement sourceHost but is not defined as a source.";
    }

    {
      assertion = cfg.targets ? "${movement.targetHost}";
      message = "Host ${movement.targetHost} is used as a movement targetHost but is not defined as a target.";
    }
  ]) cfg.movements;
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
        };

        targets = lib.mkOption {
          type = types.attrsOf targetType;
        };

        movements = lib.mkOption {
          type = types.listOf movementType;
        };
      };
    };
  };

  config = {
    assertions = hostNameAssertions ++ movementAssertions;
  };
}
