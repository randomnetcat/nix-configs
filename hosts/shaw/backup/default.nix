{ config, lib, pkgs, ... }:

let
  sourceHosts = {
    reese = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkOFn/HmrUFe3/I8JI4tsRRmTtsjmSjMYruVaxrzmoV root@reese";
    };
  };

  dataPool = "nas_oabrke";
  backupsDataset = "${dataPool}/data/backups";
  zfsBin = lib.getExe' config.boot.zfs.package "zfs";
in
{
  imports = [ 
    ./dest.nix
  ];

  config = {
    services.sanoid = {
      enable = true;
      interval = "*:0/15";
      extraArgs = [ "--verbose" "--debug" ];

      templates."safe_backup" = {
        yearly = 999999;
        monthly = 999999;
        weekly = 999999;
        daily = 999999;
        hourly = 0;

        autosnap = false;
        autoprune = true;
      };

      datasets."nas_oabrke/data/backups/groves" = {
        useTemplate = [ "safe_backup" ];
        recursive = "zfs";
      };
    };
  };
}
