{ config, lib, pkgs, ... }:

{
  imports = [ 
    ../../../sys/wants/backup
  ];

  config = {
    randomcat.backups.dest = {
      enable = true;
      parentDataset = "nas_oabrke/data/backups";

      acceptSources = {
        groves = {};
        reese.sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkOFn/HmrUFe3/I8JI4tsRRmTtsjmSjMYruVaxrzmoV root@reese";
      };
    };
  };
}
