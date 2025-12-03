{ config, lib, pkgs, ... }:

{
  config = {
    randomcat.services.backups = {
      fromNetwork = true;

      target = {
        encryptedSyncKey = ../secrets/sync-key;
        enableLegacyMountPoint = true;
        enableMetrics = true;
      };
    };
  };
}
