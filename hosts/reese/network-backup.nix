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
    ../../sys/wants/backup/network.nix
    ../../sys/impl/fs-keys.nix
  ];

  config = {
    programs.ssh.knownHosts = lib.mkMerge (lib.mapAttrsToList
      (name: value: lib.mkIf (value.hostKey != null) {
        "[${name}]:2222".publicKey = value.hostKey;
      })
      network.hosts);

    randomcat.services.backups = {
      fromNetwork = true;

     source.ssh = {
        enable = true;
        enableVpnAddresses = true;
      };
    };
  };
}
