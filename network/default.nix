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
          tailscaleIP4 = "100.91.170.206";
          tailscaleIP6 = "fd7a:115c:a1e0:52a9:3704:2f18:e2ca:626a";
        };

        carter = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHHHYG6A995Po05+JXQsvB79ZoIiSOJnW6AiJgVYPic";
          tailscaleIP4 = "100.78.202.172";
          tailscaleIP6 = "fd7a:115c:a1e0:e7f4:1215:5998:f67:c202";
          isPortable = true;
        };

        leon = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJCuMBdSMXPBTj00Z4oRcFuo/BEzbVogwYsvixhkBuU9";

          # Outdated: not set up with unspecified.systems.
          tailscaleIP4 = "100.94.148.11";
          tailscaleIP6 = "fd7a:115c:a1e0::d401:940b";
        };

        reese = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPd0qGxvcMLDwX1bqYpwOUL5c/CIgBllMFr+bGkwiwAn";
          tailscaleIP4 = "100.98.105.253";
          tailscaleIP6 = "fd7a:115c:a1e0:1f6e:62c0:45c3:6b41:6403";
        };

        shaw = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMC0AomCZZiUV/BCpImiV4p/vGvFaz5QNc+fJLXmS5p";
          tailscaleIP4 = "100.109.173.202";
          tailscaleIP6 = "fd7a:115c:a1e0:9be9:6c5a:2f1d:db18:4d1a";
        };

        groves = {
          hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQNZ/Q+x7mDYfYXftpZpWkfPByyMBbYmVFobM4vSDW2";
          tailscaleIP4 = "100.107.165.89";
          tailscaleIP6 = "fd7a:115c:a1e0:3b74:f0e9:bc73:50fa:134f";
        };
      };

      backups = {
        sources = {
          reese = { };
          carter = { };
          bear = { };
          groves = { };
        };

        targets = {
          shaw = {
            syncKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILgZ9hC4iGeYOxKaiN9w9JuIv30KYBv7k9cdtAkd0COg";
          };
        };

        movements = [
          {
            sourceHost = "reese";
            targetHost = "shaw";

            datasets = [
              {
                source = "rpool_sggau1/reese";
                target = "nas_oabrke/data/backups/reese";
                datasetName = "system";
              }
            ];
          }

          {
            sourceHost = "carter";
            targetHost = "shaw";

            # carter is a laptop, so backups might fail if it is off.
            alertOnServiceFailure = false;

            datasets = [
              {
                source = "rpool_ez8ryx/carter";
                target = "nas_oabrke/data/backups/carter";
                datasetName = "safe";
              }
            ];
          }

          {
            sourceHost = "bear";
            targetHost = "shaw";

            datasets = [
              {
                source = "rpool_zpnzkc/bear";
                target = "nas_oabrke/data/backups/bear";
                datasetName = "safe";
              }
            ];
          }

          {
            sourceHost = "groves";
            targetHost = "shaw";

            datasets = [
              {
                source = "rpool_fxooop/groves";
                target = "nas_oabrke/data/backups/groves";
                datasetName = "safe";
              }
            ];
          }
        ];
      };
    };
  };
}
