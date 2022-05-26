{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = let zfsMount = import ../zfs-mount.nix; in {
    fileSystems."/home/randomcat/games/steam_library" = zfsMount "local/steam";
  };
}
