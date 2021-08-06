{
  randomcat-server =
    { config, pkgs, modulesPath, ... }:
    {
      deployment.targetHost = "51.222.27.55";

      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./modules/system-types/basic-ovh.nix
        ./modules/wants/ssh-access.nix
        ./modules/wants/local-root-access.nix
        ./modules/wants/agorabot.nix
        ./modules/wants/agorabot-server.nix
      ];

      services.randomcat.agorabot-server = {
        enable = true;
        user = "discord-bot";
      };

      users.users.discord-bot = {
        group = "discord-bot";
      };

      users.groups.discord-bot = {
        members = [ "discord-bot" ];
      };

      services.randomcat.agorabot-server.instances = {
        "agora-prod" = {
          package = import (builtins.fetchGit {
            url = "https://github.com/randomnetcat/AgoraBot.git";
            ref = "main";
            rev = "a06baa0adad3f3f4d81e09e607c3d32dc18d0538";
          }) { inherit (pkgs); };

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
      };
    };
 }
