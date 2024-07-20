{ config, lib, pkgs, ... }:

let
  hostName = config.networking.hostName;

  network = import ../../network/common.nix;
  backups = (import ../../network/backups.nix).backups;
  hostMovements = lib.filter (m: m.sourceHost == hostName) backups.movements;

  hostDatasets = lib.concatMap (m: map (d: {
    inherit (m) targetHost;
    inherit (d) source target;
  }) m.datasets) hostMovements;

  sshKeySecret = ./secrets/sync-key;
in
{
  imports = [
    ../../sys/impl/fs-keys.nix
  ];

  config = {
    programs.ssh.knownHosts = lib.mkMerge (lib.mapAttrsToList (name: value: lib.mkIf (value ? hostKey) {
      "[${name}]:2222".publicKey = value.hostKey;
    }) network.hosts);

    services.syncoid = {
      enable = true;

      interval = "*-*-* 06:00:00 UTC";

      commands = lib.mkMerge (lib.imap0 (i: m: {
        "randomcat-${toString i}-${m.targetHost}" = {
          source = m.source;
          target = "sync-${hostName}@${m.targetHost}:${backups.hosts."${m.targetHost}".destDataset}/${hostName}/${m.target}";
          recursive = true;
          sshKey = "/run/keys/sync-key";
          localSourceAllow = [ "bookmark" "hold" "send" "snapshot" "destroy" "mount" ];
          
          extraArgs = [
            "--no-privilege-elevation"
            "--keep-sync-snap"
            "--no-rollback"
            "--sshport=2222"
          ];
        };
      }) hostDatasets);
    };

    systemd.services = lib.mkMerge (lib.imap0 (i: m: {
      "syncoid-randomcat-${toString i}-${m.targetHost}" = {
        requires = [ "sync-creds.service" ];
        after = [ "sync-creds.service" ];

        unitConfig = {
          StartLimitBurst = 3;
          StartLimitIntervalSec = "12 hours";
        };

        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "15min";
          TimeoutStartSec = "2 hours";
        };
      };
    }) hostDatasets);

    users.users.syncoid.extraGroups = [ "keys" ];

    randomcat.services.fs-keys.sync-creds = {
      keys.sync-key = {
        user = config.users.users.syncoid.name;
        source.encrypted.path = ./secrets/sync-key;
      };
    };
  };
}
