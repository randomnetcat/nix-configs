{ config, lib, utils, pkgs, ... }:

let
  cfg = config.randomcat.services.zfs;

  anyDatasets = lib.length (lib.attrsToList cfg.datasets) > 0;

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

      mountOptions = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      zfsPermissions.users = lib.mkOption {
        type = types.attrsOf (types.listOf types.str);
        default = { };
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
  permsServiceName = datasetName: "zfs-permissions-${lib.replaceStrings ["/"] ["-"] datasetName}";

  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
  isNixDataset = fs: fs.mountpoint != null && fs.mountpoint != "none";
  nixDatasets = lib.filter isNixDataset (lib.attrValues cfg.datasets);
in
{
  options = {
    randomcat.services.zfs = {
      datasets = lib.mkOption {
        type = types.attrsOf datasetType;
        default = { };
      };
    };
  };

  config = lib.mkIf anyDatasets {
    boot.supportedFilesystems.zfs = true;

    boot.zfs.extraPools = map (datasetValue: lib.head (lib.splitString "/" datasetValue.datasetName)) (lib.attrValues cfg.datasets);

    systemd.services = lib.mkMerge (map
      (datasetValue:
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

          permissionEntries = lib.attrsToList datasetValue.zfsPermissions.users;
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
                  [ "-u" ] ++
                  (lib.concatMap ({ name, value }: [ "-o" "${name}=${value}" ]) (lib.attrsToList zfsOptions)) ++
                  [ datasetName ];

                setOpts =
                  [ "-u" ] ++
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

          "${permsServiceName datasetName}" = lib.mkIf ((lib.length permissionEntries) != 0) {
            wantedBy = [ "multi-user.target" "zfs.target" ];
            before = [ "multi-user.target" "zfs.target" ];

            requires = [ "${createServiceName datasetName}.service" ];
            after = [ "${createServiceName datasetName}.service" ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };

            script = ''
              ${lib.concatMapStringsSep "\n" ({ name, value }: lib.escapeShellArgs [
                zfsBin
                "allow"
                "-u"
                name
                (lib.concatStringsSep "," value)
                datasetName
              ]) permissionEntries}
            '';

            postStop = ''
              ${lib.concatMapStringsSep "\n" ({ name, value }: lib.escapeShellArgs [
                zfsBin
                "unallow"
                "-u"
                name
                datasetName
              ]) permissionEntries}
            '';
          };
        }
      )
      (lib.attrValues cfg.datasets));

    fileSystems = lib.mkMerge (map
      (datasetValue: {
        "${datasetValue.mountpoint}" = {
          fsType = "zfs";
          device = datasetValue.datasetName;
          options = datasetValue.mountOptions;
        };
      })
      nixDatasets);

    assertions = (map
      (datasetValue: {
        assertion = !(utils.fsNeededForBoot config.fileSystems."${datasetValue.mountpoint}");
        message = "Cannot zfs-create dataset for mount ${datasetValue.mountpoint}, as it is needed for boot.";
      })
      nixDatasets) ++ (map
      (
        (datasetValue: {
          assertion = (datasetValue.mountOptions != [ ]) -> (isNixDataset datasetValue);
          message = "mountOptions is only implemented for datasets with fixed mount points";
        })
      )
      (lib.attrValues cfg.datasets));
  };
}
