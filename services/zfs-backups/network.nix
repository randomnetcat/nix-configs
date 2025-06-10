{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.backups;
  network = config.randomcat.network;
  hostName = config.networking.hostName;

  # TODO maybe handle case where (network.hosts.foo.hostName != "foo")
  selfHostAttr = hostName;

  isSource = network.backups.sources ? "${selfHostAttr}";
  isTarget = network.backups.targets ? "${selfHostAttr}";

  movementSshUser = networkMovement: "backup-${networkMovement.targetHost}";
  movementSyncoidTag = networkMovement: "${networkMovement.sourceHost}:${networkMovement.targetHost}";

  networkToLocalMovements = networkMovement: map
    (dataset: {
      sourceUser = movementSshUser networkMovement;
      sourceHost = network.hosts."${networkMovement.sourceHost}".tailscaleIP4;
      sourceDataset = "${dataset.source}/${dataset.datasetName}";
      targetParentDataset = dataset.target;
      targetChildDataset = dataset.datasetName;
      syncoidTag = movementSyncoidTag networkMovement;
      enableSyncSnapshots = true;

      inherit (networkMovement) alertOnServiceFailure;
    })
    networkMovement.datasets;

  networkToAcceptTarget = networkMovement: {
    "${networkMovement.targetHost}" = {
      user = movementSshUser networkMovement;
      authorizedKeys = [ network.backups.targets."${networkMovement.targetHost}".syncKey ];
      sourceDatasets = map (d: "${d.source}/${d.datasetName}") networkMovement.datasets;
      syncoidTag = movementSyncoidTag networkMovement;
      enableSyncSnapshots = true;
    };
  };
in
{
  imports = [
    ./source.nix
    ./target.nix
    ../../network/options/backups.nix
    ../../network/options/hosts.nix
  ];

  options = {
    randomcat.services.backups = {
      fromNetwork = lib.mkEnableOption "Automatically set backup configuration from network configuration";

      source.fromNetwork = lib.mkEnableOption "Automatically set backup source configuration from network configuration";
      target.fromNetwork = lib.mkEnableOption "Automatically set backup target configuration from network configuration";
    };
  };

  config = {
    randomcat.services.backups = lib.mkMerge [
      {
        source.fromNetwork = lib.mkDefault cfg.fromNetwork;
        target.fromNetwork = lib.mkDefault cfg.fromNetwork;
      }

      {
        source = lib.mkIf cfg.source.fromNetwork {
          enable = lib.mkDefault isSource;
          acceptTargets = lib.mkMerge (map networkToAcceptTarget (lib.filter (m: m.sourceHost == selfHostAttr) network.backups.movements));
        };

        target = lib.mkIf cfg.target.fromNetwork {
          enable = lib.mkDefault isTarget;
          movements = lib.mkMerge (
            (lib.concatMap
              (networkMovement: map
                (localMovement: {
                  "${networkMovement.sourceHost}-${localMovement.targetChildDataset}" = localMovement;
                })
                (networkToLocalMovements networkMovement))
              (lib.filter (m: m.targetHost == selfHostAttr) (lib.optionals isTarget network.backups.movements)))
          );
        };
      }
    ];
  };
}
