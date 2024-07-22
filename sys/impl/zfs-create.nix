{ config, lib, utils, pkgs, ... }:

let
  cfg = config.randomcat.services.zfs.create;

  types = lib.types;

  datasetType = types.submodule ({ name, ... }: {
    options = {
      zfsOptions = lib.mkOption {
        type = types.attrsOf types.str;
        description = "ZFS attributes to set on the dataset";
      };
    };
  });

  createServiceName = datasetName: "zfs-create-${lib.replaceStrings ["/"] ["-"] datasetName}";

  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
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
    systemd.services = lib.mkMerge (lib.mapAttrsToList (datasetName: datasetValue:
      let
        zfsOptions = datasetValue.zfsOptions;

        datasetParts = lib.splitString "/" datasetName;
        parentParts = lib.sublist 0 ((lib.length datasetParts) - 1) datasetParts;
        parentName = lib.concatStringsSep "/" parentParts;
        parentUnits = lib.optional (cfg.datasets ? "${parentName}") "${createServiceName parentName}.service";

        # TODO: this logic is untested and who knows if it works? but I feel bad not attempting to handle this at all, so...
        hasMountpoint = (zfsOptions ? mountpoint) && (zfsOptions.mountpoint != "none") && (zfsOptions.mountpoint != "legacy");
        mountUnits = lib.optional hasMountpoint "${utils.escapeSystemdPath zfsOptions.mountpoint}.mount";
      in
      {
        "${createServiceName datasetName}" = {
          wants = [ "zfs-import.target" ];
          requires = parentUnits;
          after = parentUnits ++ [ "zfs-import.target" ];

          wantedBy = mountUnits ++ [ "local-fs.target" "zfs.target" ];
          before = mountUnits ++ [ "local-fs.target" "zfs.target" "shutdown.target" ];
          conflicts = [ "shutdown.target" ];

          unitConfig = {
            DefaultDependencies = false;
            RequiresMountsFor = [ "/" ] ++ (lib.optional hasMountpoint (dirOf zfsOptions.mountpoint));
          };

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script =
            let
              createOpts = lib.concatMap ({ name, value }: [ "-o" "${name}=${value}" ]) (lib.attrsToList zfsOptions);
              setOpts = lib.mapAttrsToList (name: value: "${name}=${value}") zfsOptions;
            in
            ''
              set -euo pipefail

              if ${lib.escapeShellArgs [ zfsBin "list" "-Ho" "name" datasetName ]}; then
                printf "Dataset %s already exists; not creating.\n" ${lib.escapeShellArg datasetName}

                ${lib.escapeShellArgs ([ zfsBin "set" ] ++ setOpts ++ [ datasetName ])}
                printf "Updated optiosn for dataset %s\n" ${lib.escapeShellArg datasetName}
              else
                ${lib.escapeShellArgs ([ zfsBin "create" datasetName ] ++ createOpts)}
                printf "Created dataset %s\n" ${lib.escapeShellArg datasetName}
              fi
            '';
        };
      }
    ) cfg.datasets);
  };
}
