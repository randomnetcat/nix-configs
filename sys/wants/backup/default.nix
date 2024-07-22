{ config, lib, pkgs, ... }:

{
  imports = [ 
    ./source.nix
    ./target.nix
    ./network.nix
  ];

  # config = {
  #   services.sanoid = {
  #     enable = true;
  #     interval = "*:0/15";
  #     extraArgs = [ "--verbose" "--debug" ];

  #     templates."safe_backup" = {
  #       yearly = 999999;
  #       monthly = 999999;
  #       weekly = 999999;
  #       daily = 999999;
  #       hourly = 0;

  #       autosnap = false;
  #       autoprune = true;
  #     };

  #     datasets."nas_oabrke/data/backups/groves" = {
  #       useTemplate = [ "safe_backup" ];
  #       recursive = "zfs";
  #     };
  #   };
  # };
}
