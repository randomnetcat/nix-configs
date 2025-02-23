{ config, pkgs, ... }:

let
  path = "/home/randomcat/games/steam_library";
in
{
  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems.${path} = zfsMount "local/steam";

    systemd.tmpfiles.settings."randomcat-games-steam".${path} = {
      z = {
        user = config.users.users.randomcat.name;
        group = config.users.users.randomcat.group;
        mode = "0700";
      };
    };
  };
}
