{ config, lib, pkgs, ... }:

{
  imports = [
    ./options/hosts.nix
    ./options/backups.nix
  ];

  config = {
    randomcat.network = {
      hosts = {
        shaw = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMC0AomCZZiUV/BCpImiV4p/vGvFaz5QNc+fJLXmS5p root@shaw";
        };

        reese = {};
        groves = {};
      };

      backups = {
        sources = {
          reese = {
            syncKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkOFn/HmrUFe3/I8JI4tsRRmTtsjmSjMYruVaxrzmoV";
          };

          groves = {
            syncKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICH8LCAeIbGW+TRmKwoAwVa2m1JMWqLvOhKOsx+7Fg7u";
          };
        };

        targets = {
          shaw = {
            backupsDataset = "nas_oabrke/data/backups";
          };
        };

        movements = [
          {
            sourceHost = "reese";
            targetHost = "shaw";

            datasets = [
              {
                source = "rpool_sggau1/reese/system";
                target = "system";
              }
            ];
          }

          {
            sourceHost = "groves";
            targetHost = "shaw";

            datasets = [
              {
                source = "rpool_fxooop/groves/safe";
                target = "safe";
              }
            ];
          }
        ];
      };
    };
  };
}
