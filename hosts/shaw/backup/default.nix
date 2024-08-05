{ config, lib, pkgs, ... }:

{
  imports = [ 
    ../../../sys/wants/backup/default.nix
    ../../../sys/wants/backup/network.nix
    ../../../network
  ];

  config = {
    randomcat.services.backups.fromNetwork = true;
  };
}
