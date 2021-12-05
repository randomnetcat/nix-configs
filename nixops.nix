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
            rev = "40a37f69da66a4cc92362cb05f12af12722c7772";
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
            rev = "77843d89a3f45b5e3f1dbffc6efc397ea6f9281d";
          }) { inherit pkgs; };

          token = builtins.readFile ./secrets/discord/secret-hitler-token;

          configSource = ./public-config/agorabot/secret-hitler;
          dataVersion = 1;
        };
      };

      features.trungle-access.enable = true;
     };
 }
