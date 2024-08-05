{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.backups;
  network = config.randomcat.network;
  hostName = config.networking.hostName;

  # TODO maybe handle case where (network.hosts.foo.hostName != "foo")
  selfHostAttr = hostName;

  isSource = network.backups.sources ? "${selfHostAttr}";
  isTarget = network.backups.targets ? "${selfHostAttr}";

  movementSshUser = networkMovement: "sync-${networkMovement.sourceHost}";
  movementSyncoidTag = networkMovement: "${networkMovement.sourceHost}:${networkMovement.targetHost}";

  networkToLocalMovements = networkMovement: map (dataset: {
    targetName = networkMovement.targetHost;
    targetHost = network.hosts."${networkMovement.targetHost}".hostName;
    targetUser = movementSshUser networkMovement;
    sourceDataset = dataset.source;
    targetDataset = "${network.backups.targets."${networkMovement.targetHost}".backupsDataset}/${networkMovement.sourceHost}/${dataset.target}";
  }) networkMovement.datasets;

  networkToTargetSources = networkMovement: {
    "${networkMovement.sourceHost}" = {
      user = movementSshUser networkMovement;
      sshKey = network.backups.sources."${networkMovement.sourceHost}".syncKey;
      childDataset = networkMovement.sourceHost;
      syncoidTag = movementSyncoidTag networkMovement;
    };
  };
in
{
  imports = [
    ./source.nix
    ./target.nix
    ../../../network/options/backups.nix
    ../../../network/options/hosts.nix
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
          movements = lib.mkIf isSource (lib.concatMap networkToLocalMovements (lib.filter (m: m.sourceHost == selfHostAttr) network.backups.movements));
        };

        target = lib.mkIf cfg.target.fromNetwork {
          enable = lib.mkDefault isTarget;
          parentDataset = network.backups.targets."${selfHostAttr}".backupsDataset;
          acceptSources = lib.mkMerge (map networkToTargetSources (lib.filter (m: m.targetHost == selfHostAttr) network.backups.movements));
        };
      }
    ];
  };
}
