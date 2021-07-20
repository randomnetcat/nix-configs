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
    
    fileSystems."/root/mountpoints/dev_projects" = {
      device = "/dev/mapper/vg_rcat-data_dev_projects";
      fsType = "ext4";
    };

    fileSystems."/home/randomcat/dev/projects" = {
      device = "/root/mountpoints/dev_projects";
      fsType = "fuse.bindfs";
      options = [ "force-user=randomcat" "force-group=randomcat" ];
    };
  };
}
