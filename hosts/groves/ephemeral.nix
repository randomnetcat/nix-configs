{ config, lib, pkgs, ... }:

{
  imports = [
    ./mounts/feature/ephemeral.nix
  ];

  config = {
    # Provide a mountpoint on a ZFS dataset that is not backed up.
    systemd.tmpfiles.settings."10-ephemeral" = {
      "/mnt/ephemeral/root".d = {
        user = "root";
        group = "root";
        mode = "0700";
      };

      "/mnt/ephemeral/randomcat".d = {
        user = config.users.users.randomcat.name;
        group = config.users.users.randomcat.group;
        mode = "0700";
      };
    };
  };
}
