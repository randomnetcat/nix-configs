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

    containers.archive = {
      config = { pkgs, ... }: {
        environment.systemPackages = [
          pkgs.wireguard-tools
          pkgs.python3
          pkgs.yt-dlp
          pkgs.deno
          pkgs.ffmpeg
        ];

        users.users.archive = {
          isNormalUser = true;

          uid = config.users.users.archive.uid;
          group = "archive";
        };

        users.groups.archive = {
          gid = config.users.groups.archive.gid;
        };

        networking.useHostResolvConf = false;
        services.resolved.enable = true;
      };

      privateUsers = "pick";
      privateNetwork = true;

      localAddress = "10.232.149.12";
      hostAddress = "10.232.148.12";
      localAddress6 = "fd50:fe53:b223:1::2";
      hostAddress6 = "fd50:fe53:b223:2::2";

      extraFlags = [
        "--bind=/srv/archive/youtube:/srv/archive/youtube:owneridmap"
      ];
    };
  };
}
