{ pkgs, lib, ... }:

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
  imports = [
    ../../sys/impl/zfs-create.nix
  ];

  config = {
    users.users.archive = {
      isNormalUser = true;
      group = "archive";

      packages = [
        pkgs.yt-dlp
        pkgs.rclone
        pkgs.makemkv
      ];
    };

    users.groups.archive = {};

    randomcat.services.zfs.create.datasets = lib.mkMerge (
      [
        {
          "${archiveParent}" = {
            mountpoint = baseMountpoint;
          };
        }
      ] ++
      (map (child: {
        "${archiveParent}/${child}" = {
          mountpoint = "${baseMountpoint}/${child}";
        };
      }) archiveDatasets)
    );
  };
}
