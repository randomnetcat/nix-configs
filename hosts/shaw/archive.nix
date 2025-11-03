{ config, lib, pkgs, ... }:

let
  archiveParent = "nas_oabrke/data/archive";

  archiveDatasets = [
    "internet"
    "media"
    "ncsu-google"
    "nebula"
    "nomic"
    "youtube"
  ];

  baseMountpoint = "/srv/archive";
in
{
  config = {
    users.users.archive = {
      uid = 2000;
      isNormalUser = true;
      group = "archive";

      packages = [
        pkgs.yt-dlp
        pkgs.rclone
        pkgs.makemkv
      ];

      openssh.authorizedKeys = (config.users.users.randomcat.openssh.authorizedKeys or { });
    };

    users.groups.archive = {
      gid = config.users.users.archive.uid;
    };

    randomcat.services.zfs.datasets = lib.mkMerge (
      [
        {
          "${archiveParent}" = {
            mountpoint = baseMountpoint;
            mountOptions = [ "nofail" ];
          };
        }
      ] ++
      (map
        (child: {
          "${archiveParent}/${child}" = {
            mountpoint = "${baseMountpoint}/${child}";
            mountOptions = [ "nofail" ];
          };
        })
        archiveDatasets)
    );
  };
}
