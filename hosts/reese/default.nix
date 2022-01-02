{ config, pkgs, modulesPath, ... }:
{
  deployment.targetHost = "reese.randomcat.org";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/system-types/oracle-arch.nix
    ../../modules/wants/ssh-access.nix
    ../../modules/wants/zulip-server
    ../../modules/wants/agorabot-server
    ../../modules/wants/trungle-access.nix
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

  nix.trustedUsers = [ "remote-build" ];

  services.randomcat.agorabot-server = {
    enable = true;
  };

  services.randomcat.agorabot-server.instances = {
    "agora-prod" = {
      package = import (builtins.fetchGit {
        url = "https://github.com/randomnetcat/AgoraBot.git";
        ref = "main";
        rev = "82e3695394acd7a1b4632882b18f2ffded38ae78";
      }) { inherit pkgs; };

      tokenEncryptedFile = ./secrets/discord-token-agora-prod.age;

      configSource = ./public-config/agorabot/agora-prod;

      secretConfigFiles = {
        "digest/ssmtp.conf" = {
          encryptedFile = ./secrets/discord-config-agora-prod-ssmtp.age;
        };
      };

      extraConfigFiles = {
        "digest/mail.json" = {
          text = ''
            {
              "send_strategy": "ssmtp",
              "ssmtp_path": "${pkgs.ssmtp}/bin/ssmtp",
              "ssmtp_config_path": "ssmtp.conf"
            }
          '';
        };
      };

      dataVersion = 1;
    };

    "secret-hitler" = {
      package = import (builtins.fetchGit {
        url = "https://github.com/randomnetcat/AgoraBot.git";
        ref = "secret-hitler";
        rev = "4c38facf4bad7950624a9c523c20c8cdd0b33f7c";
      }) { inherit pkgs; };

      tokenEncryptedFile = ./secrets/discord-token-secret-hitler.age;

      configSource = ./public-config/agorabot/secret-hitler;
      dataVersion = 1;
    };
  };

  features.trungle-access.enable = true;

  services.resolved.enable = true;
 }
