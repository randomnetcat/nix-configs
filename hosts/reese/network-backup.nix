{ config, lib, pkgs, ... }:

let
  network = config.randomcat.network;

  hostName = config.networking.hostName;

  backups = network.backups;
  hostMovements = lib.filter (m: m.sourceHost == hostName) backups.movements;

  hostDatasets = lib.concatMap
    (m: map
      (d: {
        inherit (m) targetHost;
        inherit (d) source target;
      })
      m.datasets)
    hostMovements;

  sshKeySecret = ./secrets/sync-key;
in
{
  imports = [
    ../../network
    ../../sys/impl/fs-keys.nix
  ];

  config = {
    randomcat.services.backups = {
      fromNetwork = true;
    };
  };
}
