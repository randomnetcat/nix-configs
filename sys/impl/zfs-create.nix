{ config, lib, utils, pkgs, ... }:

let
  cfg = config.randomcat.services.zfs.create;

  types = lib.types;

  datasetType = types.submodule ({ name, config, ... }: {
    options = {
      datasetName = lib.mkOption {
        type = types.str;
        default = name;
      };

      zfsOptions = lib.mkOption {
        type = types.attrsOf types.str;
        description = "ZFS attributes to set on the dataset";
      };

      mountpoint = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };

    config = {
      # If the Nix-managed mountpoint is set, force ZFS mountpoint to be legacy.
      zfsOptions.mountpoint = lib.mkIf (config.mountpoint != null) (
        if config.mountpoint == "none" then "none" else "legacy"
      );
    };
  });

  createServiceName = datasetName: "zfs-create-${lib.replaceStrings ["/"] ["-"] datasetName}";

  zfsBin = lib.getExe' config.boot.zfs.package "zfs";

  nixDatasets = lib.filter (fs: fs.mountpoint != null && fs.mountpoint != "none") (lib.attrValues cfg.datasets);
in
{
  options = {
    randomcat.services.zfs.create = {
      datasets = lib.mkOption {
        type = types.attrsOf datasetType;
      };
    };
  };

  config = {
    systemd.services = lib.mkMerge (map (datasetValue:
      let
        datasetName = datasetValue.datasetName;
        zfsOptions = datasetValue.zfsOptions;

        datasetParts = lib.splitString "/" datasetName;
        parentParts = lib.sublist 0 ((lib.length datasetParts) - 1) datasetParts;
        parentName = lib.concatStringsSep "/" parentParts;
        parentUnits = lib.optional (cfg.datasets ? "${parentName}") "${createServiceName parentName}.service";

        hasZfsMountpoint = (zfsOptions ? mountpoint) && (zfsOptions.mountpoint != "none") && (zfsOptions.mountpoint != "legacy");

        hasNixMountpoint = datasetValue.mountpoint != null && datasetValue.mountpoint != "none";
        nixMountpoint = datasetValue.mountpoint;

        # TODO: this logic is untested and who knows if it works? but I feel bad not attempting to handle this at all, so...
        mountUnits = lib.optional hasNixMountpoint "${utils.escapeSystemdPath nixMountpoint}.mount";
        fsDependents = lib.optionals (!hasNixMountpoint) [ "local-fs.target" "zfs.target" ];
      in
      {
        "${createServiceName datasetName}" = {
          wants = [ "zfs-import.target" ];
          requires = parentUnits;
          after = parentUnits ++ [ "zfs-import.target" ];

          wantedBy = fsDependents;
          requiredBy = mountUnits;
          before = mountUnits ++ fsDependents ++ [ "shutdown.target" ];
          conflicts = [ "shutdown.target" ];

          unitConfig = {
            DefaultDependencies = false;
            RequiresMountsFor = [ "/" ] ++ (lib.optional hasZfsMountpoint (dirOf zfsOptions.mountpoint));
          };

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script =
            let
              createOpts =
                (lib.concatMap ({ name, value }: [ "-o" "${name}=${value}" ]) (lib.attrsToList zfsOptions)) ++
                [ datasetName ];

              setOpts =
                (lib.mapAttrsToList (name: value: "${name}=${value}") zfsOptions) ++
                [ datasetName ];
            in
            ''
              set -euo pipefail

              if ${lib.escapeShellArgs [ zfsBin "list" "-Ho" "name" datasetName ]} > /dev/null 2> /dev/null; then
                printf "Dataset %s already exists; not creating.\n" ${lib.escapeShellArg datasetName}

                ${lib.escapeShellArgs ([ zfsBin "set" ] ++ setOpts)}
                printf "Updated options for dataset %s\n" ${lib.escapeShellArg datasetName}
              else
                ${lib.escapeShellArgs ([ zfsBin "create" ] ++ createOpts)}
                printf "Created dataset %s\n" ${lib.escapeShellArg datasetName}
              fi
            '';
        };
      }
    ) (lib.attrValues cfg.datasets));

    fileSystems = lib.mkMerge (map (datasetValue: {
      "${datasetValue.mountpoint}" = {
        fsType = "zfs";
        device = datasetValue.datasetName;
      };
    }) nixDatasets);

    assertions = map (datasetValue: {
      assertion = !(utils.fsNeededForBoot config.fileSystems."${datasetValue.mountpoint}");
      message = "Cannot zfs-create dataset for mount ${datasetValue.mountpoint}, as it is needed for boot.";
    }) nixDatasets;
  };
}
