{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../sys/wants/agorabot
  ];

  config = {
    randomcat.services.agorabot = {
      instances = let package = (pkgs.extend inputs.agorabot-prod.overlays.default).randomcat.agorabot; in {
        "agora-prod" = {
          enable = true;

          inherit package;
          dataVersion = 1;
          tokenCredFile = ./secrets/agorabot-agora-prod-token;
          configSource = ./public-config/agorabot/agora-prod;

          secretConfig = {
            "digest/msmtp.conf" = {
              credFile = ./secrets/agorabot-agora-prod-config-digest-msmtp.conf;
            };
          };

          extraConfig = {
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
        };

        "secret-hitler" = {
          enable = true;

          inherit package;
          tokenCredFile = ./secrets/agorabot-secret-hitler-token;
          configSource = ./public-config/agorabot/secret-hitler;
          dataVersion = 1;
        };
      };
    };
  };
}
