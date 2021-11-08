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

      # Have to use external nameserver because Oracle nameserver is on a link-local address (169.254.x.x) and docker adds routes for those addresses for its network adapters.
      networking.nameservers = [ "1.1.1.1" ];

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
            rev = "47b296cb2db37fb0221124a49afbb781cf393dea";
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
            rev = "944ce1b32abb5151b09eadb69493301808da7fb6";
          }) { inherit pkgs; };

          token = builtins.readFile ./secrets/discord/secret-hitler-token;

          configSource = ./public-config/agorabot/secret-hitler;
          dataVersion = 1;
        };
      };
     };
 }
