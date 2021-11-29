{
    oracle-server = 
    { config, pkgs, modulesPath, ... }:
    {
      deployment.targetHost = "oracle-server.randomcat.org";

      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./modules/system-types/oracle-arch.nix
        ./modules/wants/ssh-access.nix
        ./modules/wants/zulip-server.nix
        ./modules/wants/agorabot-server.nix
        ./modules/impl/secrets
      ];

      boot.cleanTmpDir = true;
      networking.hostName = "instance-20211029-1400";
      networking.firewall.allowPing = true;
      services.openssh.enable = true;

      virtualisation.docker.enable = true;

      randomcat.secrets = {
        sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOccenq6rA3lk3UtC0ywkJiiNV+76o6RQsfIQMY8cLw5 root@instance-20211029-1400";

        secrets = {
        };
      };

      services.randomcat.docker-zulip = {
        enable = true;

        secrets = {
          memcachedPass = builtins.readFile ./secrets/zulip/memcached_pw;
          rabbitMqPass = builtins.readFile ./secrets/zulip/rabbitmq_pw;
          postgresPass = builtins.readFile ./secrets/zulip/postgres_pw;
          redisPass = builtins.readFile ./secrets/zulip/redis_pw;
          zulipSecretKey = builtins.readFile ./secrets/zulip/secret_key;
          emailPassword = builtins.readFile ./secrets/zulip/sendgrid_api_key;
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
            rev = "ac582130315fe0dba38dfc3f02f5a397b7961033";
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
     };
 }
