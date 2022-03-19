{ config, pkgs, modulesPath, ... }:
{
  deployment.targetHost = "reese";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/system-types/oracle-arch.nix
    ../../modules/wants/ssh-access.nix
    ../../modules/wants/zulip-server
    ../../modules/wants/agorabot-server
    ../../modules/wants/trungle-access.nix
    ../../modules/wants/tailscale.nix
    ../../modules/impl/secrets
  ];

  boot.cleanTmpDir = true;
  networking.hostName = "reese";
  networking.firewall.allowPing = true;
  services.openssh.enable = true;

  users.users.remote-build = {
    isNormalUser = true;
    group = "remote-build";

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC06hArkl5doDuQeOGemytTzpSHMrCIYWae9/LfYRlxMR4EsX/UAELR+s/+su5RZjsKKgFlw5kAI+RvrtV9PkToOTEZCc1qZR4PDCv1aMUCUaxlMgEwNel8Wtt8IcbURCBPa28jZKnrJ24ZhsweXLgY1ZzPO2Uza1ZMOgALLSs7xOKd13nqehg7wOjX+zJAaJL73DTi8leeUsONIjGqsuPn6/yy7iH+chgYbb1ssjLNfsLVFih+fklL5vKv6sWbZud7dbQV2FVic1Kqc0pVL6xQVXL9hJo8WBgz/FTF933jRHWawOWDZYIl2OM3zt+jOHcJ3PM0pVXMktLXrDxqRJidYytNDhAfntooM5LQ612LGhRmHBvL1z5Qau14AhnEOqaLYtnMNif0ivKyNVaLYo8MrV5DoFjYcz8g4mOuM++JZ9Uo2MLAiGGWGdwo7bYWEmRJ6o36ZptE5e8Kvc4BsSwnI5axEU4HWGdHELT+sLqrt7Za5p87Z3mvkzxBTeRFKvM= root@randomcat-laptop-nixos"
    ];
  };

  users.groups.remote-build = {};

  nix.settings.trusted-users = [ "remote-build" ];

  services.randomcat.agorabot-server = {
    enable = true;
  };

  services.randomcat.agorabot-server.instances = {
    "agora-prod" = {
      # Package set in flake.nix

      tokenEncryptedFile = ./secrets/discord-token-agora-prod.age;

      configSource = ./public-config/agorabot/agora-prod;

      secretConfigFiles = {
        "digest/msmtp.conf" = {
          encryptedFile = ./secrets/discord-config-agora-prod-msmtp.age;
        };
      };

      extraConfigFiles = {
        "digest/mail.json" = {
          text = ''
            {
              "send_strategy": "msmtp",
              "msmtp_path": "${pkgs.msmtp}/bin/msmtp",
              "msmtp_config_path": "msmtp.conf"
            }
          '';
        };
      };

      dataVersion = 1;
    };

    "secret-hitler" = {
      # Package set in flake.nix

      tokenEncryptedFile = ./secrets/discord-token-secret-hitler.age;

      configSource = ./public-config/agorabot/secret-hitler;
      dataVersion = 1;
    };
  };

  features.trungle-access.enable = true;

  services.resolved.enable = true;

  services.resolved.extraConfig = ''
    DNS=1.1.1.1%enp0s3#cloudflare-dns.com 1.0.0.1%enp0s3#cloudflare-dns.com 2606:4700:4700::1111%enp0s3#cloudflare-dns.com 2606:4700:4700::1001%enp0s3#cloudflare-dns.com
  '';

  randomcat.tailscale = {
    enable = true;
    authkeyPath = "/run/keys/tailscale-authkey";
  };

  randomcat.secrets.secrets."tailscale-authkey" = {
    encryptedFile = ./secrets/tailscale-authkey;
    dest = "/run/keys/tailscale-authkey";
    owner = "root";
    group = "root";
    permissions = "700";
  };
}
