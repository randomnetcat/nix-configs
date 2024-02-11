{ pkgs, lib, ... }:

{
  config = {
    users.users.archive = {
      isNormalUser = true;
      group = "archive";

      packages = [
        pkgs.yt-dlp
        pkgs.rclone
      ];
    };

    users.groups.archive = {};
  };
}
