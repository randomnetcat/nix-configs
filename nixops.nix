{
    oracle-server = 
    { config, pkgs, modulesPath, ... }:
    {
      deployment.targetHost = "finch.randomcat.org";

      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./modules/system-types/oracle-arch.nix
        ./modules/wants/ssh-access.nix
        ./modules/wants/zulip-server
        ./modules/wants/agorabot-server
        ./modules/wants/trungle-access.nix
        ./modules/impl/secrets
      ];

      boot.cleanTmpDir = true;
      networking.hostName = "finch";
      networking.firewall.allowPing = true;
      services.openssh.enable = true;

      virtualisation.docker.enable = true;

      users.users.remote-build = {
        isNormalUser = true;
        group = "remote-build";

        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC06hArkl5doDuQeOGemytTzpSHMrCIYWae9/LfYRlxMR4EsX/UAELR+s/+su5RZjsKKgFlw5kAI+RvrtV9PkToOTEZCc1qZR4PDCv1aMUCUaxlMgEwNel8Wtt8IcbURCBPa28jZKnrJ24ZhsweXLgY1ZzPO2Uza1ZMOgALLSs7xOKd13nqehg7wOjX+zJAaJL73DTi8leeUsONIjGqsuPn6/yy7iH+chgYbb1ssjLNfsLVFih+fklL5vKv6sWbZud7dbQV2FVic1Kqc0pVL6xQVXL9hJo8WBgz/FTF933jRHWawOWDZYIl2OM3zt+jOHcJ3PM0pVXMktLXrDxqRJidYytNDhAfntooM5LQ612LGhRmHBvL1z5Qau14AhnEOqaLYtnMNif0ivKyNVaLYo8MrV5DoFjYcz8g4mOuM++JZ9Uo2MLAiGGWGdwo7bYWEmRJ6o36ZptE5e8Kvc4BsSwnI5axEU4HWGdHELT+sLqrt7Za5p87Z3mvkzxBTeRFKvM= root@randomcat-laptop-nixos"
        ];
      };

      users.groups.remote-build = {};

      nix.trustedUsers = [ "remote-build" ];

      randomcat.secrets = {
        sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOccenq6rA3lk3UtC0ywkJiiNV+76o6RQsfIQMY8cLw5 root@instance-20211029-1400";

        secrets = {
        };
      };

      services.randomcat.agorabot-server = {
        enable = true;
      };

      services.randomcat.agorabot-server.instances = {
        "agora-prod" = {
          package = import (builtins.fetchGit {
            url = "https://github.com/randomnetcat/AgoraBot.git";
            ref = "main";
            rev = "0b6f891c859f579675e453da477ad804f0ac1fcd";
          }) { inherit pkgs; };

          token = builtins.readFile ./secrets/discord/agora-prod-token;

          configSource = ./public-config/agorabot/agora-prod;

          secretConfigFiles = {
            "digest/ssmtp.conf" = {
              text = builtins.readFile ./secrets/discord/agora-prod-ssmtp-config;
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
            rev = "40fe5f0d2a98582b38fe07cba605376857f0c14c";
          }) { inherit pkgs; };

          token = builtins.readFile ./secrets/discord/secret-hitler-token;

          configSource = ./public-config/agorabot/secret-hitler;
          dataVersion = 1;
        };
      };

      features.trungle-access.enable = true;
     };
 }
