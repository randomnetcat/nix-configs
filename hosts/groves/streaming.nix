{ config, lib, pkgs, ... }:

{
  config = {
    randomcat.services.fs-keys.cifs-shaw-archive-creds = {
      requiredBy = [ "srv-archive.mount" ];
      before = [ "srv-archive.mount" ];

      keys.cifs-shaw-archive = {
        source.encrypted.path = ./secrets/cifs-shaw-archive;

        user = "root";
        group = "root";
        mode = "0400";
      };
    };

    randomcat.services.zfs.datasets."rpool_fxooop/groves/local/fscache" = {
      zfsOptions = {
        # Per https://github.com/openzfs/zfs/issues/10473#issuecomment-646211412
        "recordsize" = "4k";

        # These features are required per https://docs.kernel.org/filesystems/caching/cachefiles.html
        "xattr" = "sa";
        "atime" = "on";
      };

      mountpoint = "/mnt/fscache";
    };

    fileSystems."/srv/archive" = {
      fsType = "cifs";
      device = "//shaw.birdsong.network/archive";

      options = [
        "credentials=/run/keys/cifs-shaw-archive"
        "ro"

        "nosuid"
        "nodev"
        "noexec"

        # TODO: Convince these to work? I'm not sure why they aren't.
        # "forceuid=${toString config.users.users.archive.uid}"
        # "forcegid=${toString config.users.groups.archive.gid}"

        # Caching; depends on cachefilesd below.
        "fsc"
      ];
    };

    services.cachefilesd = {
      enable = true;
      cacheDir = "/mnt/fscache/storage";
    };
  };
}
