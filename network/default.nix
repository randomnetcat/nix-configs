{ config, lib, pkgs, ... }:

{
  imports = [
    ./options/hosts.nix
    ./options/backups.nix
  ];

  config = {
    randomcat.network = {
      hosts = {
        bear = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9Kn1CIcDHaleKHf7zO6O30Rbxs/FwL0/Ie+mEjZJr";
          tailscaleIP4 = "100.85.165.130";
          tailscaleIP6 = "fd7a:115c:a1e0:ab12:4843:cd96:6255:a582";
        };

        groves = {
          tailscaleIP4 = "100.68.110.33";
          tailscaleIP6 = "fd7a:115c:a1e0:ab12:4843:cd96:6244:6e21";
        };

        leon = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJCuMBdSMXPBTj00Z4oRcFuo/BEzbVogwYsvixhkBuU9";
          tailscaleIP4 = "100.94.148.11";
          tailscaleIP6 = "fd7a:115c:a1e0::d401:940b";
        };

        reese = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPd0qGxvcMLDwX1bqYpwOUL5c/CIgBllMFr+bGkwiwAn";
          tailscaleIP4 = "100.90.31.23";
          tailscaleIP6 = "fd7a:115c:a1e0:ab12:4843:cd96:625a:1f17";
        };

        shaw = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMC0AomCZZiUV/BCpImiV4p/vGvFaz5QNc+fJLXmS5p";
          tailscaleIP4 = "100.103.37.71";
          tailscaleIP6 = "fd7a:115c:a1e0::f567:2547";
        };
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
