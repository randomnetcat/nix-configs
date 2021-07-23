{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    environment.systemPackages = [
      pkgs.bindfs
    ];
    
    fileSystems."/root/mountpoints/games" = {
      device = "/dev/mapper/vg_rcat-data_games";
      fsType = "ext4";
    };

    fileSystems."/home/randomcat/games" = {
      device = "/root/mountpoints/games";
      fsType = "fuse.bindfs";
      options = [
        (assert (builtins.hasAttr "randomcat" config.users.users); "force-user=randomcat")
        (assert (builtins.hasAttr "randomcat" config.users.groups); "force-group=randomcat")
      ];
    };
  };
}
