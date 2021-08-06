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
      ];

      users.users.discord-bot = {
        isSystemUser = true;
        createHome = true;
        group = "discord-bot";
        home = "/srv/discord-bot";
        extraGroups = [ "keys" ];
      };

      users.groups.discord-bot = {
        members = [ "discord-bot" ];
      };

      deployment.keys.discord-agora-prod = let userCfg = config.users.users.discord-bot; in {
        text = builtins.readFile ./secrets/discord/agora-prod-token;
        user = userCfg.name;
        group = userCfg.group;
        permissions = "0640";
      };

      deployment.keys.ssmtp-agora-prod = let userCfg = config.users.users.discord-bot; in {
        text = builtins.readFile ./secrets/discord/agora-prod-ssmtp-config;
        user = userCfg.name;
        group = userCfg.group;
        permissions = "0640";
      };

      systemd.services.agorabot-create-directories = let userCfg = config.users.users.discord-bot; in {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = userCfg.name;
          Group = userCfg.group;
        };

        script = ''
          mkdir -p -- /srv/discord-bot/agora-prod
        '';
      };

      services.randomcat.agorabot.instances = {
        "agora-prod" = {
          package = import (builtins.fetchGit {
            url = "https://github.com/randomnetcat/AgoraBot.git";
            ref = "main";
            rev = "a06baa0adad3f3f4d81e09e607c3d32dc18d0538";
          }) { inherit (pkgs); };

          configGeneratorPackage =
            let
              mailConfigText = ''
                {
                  "send_strategy": "ssmtp",
                  "ssmtp_path": "${pkgs.ssmtp}/bin/ssmtp",
                  "ssmtp_config_path": "/run/keys/ssmtp-agora-prod"
                }
              '';
            in
            pkgs.writeShellScriptBin "generate-config" ''
              cp -RT --no-preserve=mode -- ${pkgs.lib.escapeShellArg "${./public-config/agorabot/agora-prod}"} "$1"
              printf "%s" ${pkgs.lib.escapeShellArg mailConfigText} > "$1"/digest/mail.json 
            '';

          dataVersion = 1;

          workingDir = "/srv/discord-bot/agora-prod";

          tokenFilePath = "/run/keys/discord-agora-prod";

          unit = let userCfg = config.users.users.discord-bot; keyServices = [ "discord-agora-prod-key.service" "ssmtp-agora-prod-key.service" ]; in {
            wantedBy = [ "multi-user.target" ];
            after = [ "agorabot-create-directories.service" ] ++ keyServices;
            wants = [] ++ keyServices;

            auth = {
              user = userCfg.name;
              group = userCfg.group;
            };
          };
        };
      };
    };
 }
