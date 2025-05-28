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
      sourceName = networkMovement.sourceHost;
      sourceUser = movementSshUser networkMovement;
      sourceHost = network.hosts."${networkMovement.sourceHost}".tailscaleIP4;
      sourceDataset = dataset.source;
      targetGroupDataset = networkMovement.sourceHost;
      targetChildDataset = dataset.target;
      syncoidTag = movementSyncoidTag networkMovement;
    })
    networkMovement.datasets;

  networkToAcceptTarget = networkMovement: {
    "${networkMovement.targetHost}" = {
      user = movementSshUser networkMovement;
      sshKey = network.backups.targets."${networkMovement.targetHost}".syncKey;
      sourceDatasets = map (d: d.source) networkMovement.datasets;
      syncoidTag = movementSyncoidTag networkMovement;
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
          movements = lib.mkIf isTarget (lib.concatMap networkToLocalMovements (lib.filter (m: m.targetHost == selfHostAttr) network.backups.movements));
        };
      }
    ];
  };
}
