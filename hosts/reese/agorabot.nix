{ config, pkgs, inputs, ... }:

{
  config = {
    randomcat.services.agorabot-server = {
      enable = true;

      instances = let package = (pkgs.extend inputs.agorabot-prod.overlays.default).randomcat.agorabot; in {
        "agora-prod" = {
          inherit package;

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
          inherit package;

          tokenEncryptedFile = ./secrets/discord-token-secret-hitler.age;
          configSource = ./public-config/agorabot/secret-hitler;
          dataVersion = 1;
        };
      };
    };
  };
}