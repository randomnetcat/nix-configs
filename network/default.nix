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

        carter = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHHHYG6A995Po05+JXQsvB79ZoIiSOJnW6AiJgVYPic";
          tailscaleIP4 = "100.101.241.29";
          tailscaleIP6 = "fd7a:115c:a1e0::101:f11f";
          isPortable = true;
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
          reese = { };
          carter = { };
          bear = { };
        };

        targets = {
          shaw = {
            backupsDataset = "nas_oabrke/data/backups";
            syncKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILgZ9hC4iGeYOxKaiN9w9JuIv30KYBv7k9cdtAkd0COg";
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
            sourceHost = "carter";
            targetHost = "shaw";

            datasets = [
              {
                source = "rpool_ez8ryx/carter/safe";
                target = "safe";
              }
            ];
          }

          {
            sourceHost = "bear";
            targetHost = "shaw";

            datasets = [
              {
                source = "rpool_zpnzkc/bear/safe";
                target = "safe";
              }
            ];
          }
        ];
      };
    };
  };
}
