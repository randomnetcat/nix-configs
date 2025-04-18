{ config, pkgs, ... }:

let
  base = "rpool_ez8ryx/carter";
  ephemeral = "${base}/local/ephemeral";
in
{
  config = let zfsMount = import ../zfs-mount.nix; in {
    randomcat.services.zfs.datasets."${ephemeral}" = {
      mountpoint = "/mnt/ephemeral";
    };
  };
}
