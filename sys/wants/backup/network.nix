{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.backups;
  network = config.randomcat.network;
  hostName = config.networking.hostName;

  # TODO maybe handle case where (network.hosts.foo.hostName != "foo")
  selfHostAttr = hostName;

  isSource = network.backups.sources ? "${hostName}";

  networkToLocalMovements = networkMovement: map (dataset: {
    targetName = networkMovement.targetHost;
    targetHost = network.hosts."${networkMovement.targetHost}".hostName;
    targetUser = "sync-${selfHostAttr}";
    sourceDataset = dataset.source;
    targetDataset = "${network.backups.targets."${networkMovement.targetHost}".backupsDataset}/${selfHostAttr}/${dataset.target}";
  }) networkMovement.datasets;
in
{
  imports = [
    ./source.nix
    ./target.nix
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
      }
    ];
  };
}
