{ config, pkgs, ... }:

{
  imports = [
    ../../network
    ../../sys/wants/backup/network.nix
  ];

  config = {
    randomcat.services.backups.source = {
      fromNetwork = true;
      encryptedSyncKey = ./secrets/sync-key;
    };
  };
}
