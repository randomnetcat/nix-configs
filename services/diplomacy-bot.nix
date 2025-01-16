{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) types;

  cfg = config.randomcat.services.diplomacy-bot;
  settingsFormat = pkgs.formats.json {};
  settingsFile = settingsFormat.generate "settings.json" cfg.settings;
  credName = "diplomacy-bot-token";
in
{
  options = {
    randomcat.services.diplomacy-bot = {
      enable = lib.mkEnableOption "diplomacy bot";

      package = (lib.mkPackageOption pkgs "diplomacy bot" { }) // {
        default = (pkgs.extend inputs.diplomacy-bot.overlay).diplomacy-bot;
        defaultText = lib.literalExpression "(pkgs.extend inputs.diplomacy-bot.overlay).diplomacy-bot";
      };

      settings = lib.mkOption {
        description = "Configuration for Diplomacy Bot.";
        default = {};

        type = types.submodule {
          freeformType = settingsFormat.type;
        };
      };

      tokenCredential = config.fountain.lib.mkCredentialOption {
        name = credName;
        description = "Diplomacy Bot Discord token";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."diplomacy-bot" = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      startLimitBurst = 10;
      startLimitIntervalSec = 30 * 60;

      serviceConfig = {
        DynamicUser = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        NoNewPrivileges = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectClock = true;
        ProtectHostname = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectControlGroups = true;
        SystemCallFilter = "@system-service";
        CapabilityBoundingSet = "";
        RestrictNamespaces = true;
        RestrictAddressFamilies = "AF_INET AF_INET6";
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        UMask = "077";
        SystemCallArchitectures = "native";
        StateDirectory = "diplomacy-bot/prod";
        StateDirectoryMode = "700";

        Restart = "on-failure";
        RestartSec = "30s";

        LoadCredentialEncrypted = [
          "${credName}:${cfg.tokenCredential}"
        ];
      };

      script = ''
        set -euo pipefail

        cd -- "$STATE_DIRECTORY"

        ${lib.escapeShellArgs [
          "ln"
          "-sfT"
          "--"
          "${settingsFile}"
          "config.json"
        ]}

        ln -sfT -- "$CREDENTIALS_DIRECTORY"/${lib.escapeShellArg credName} key.txt

        if [ ! -e game.json ]; then
          ${lib.escapeShellArgs [
            "cp"
            "--"
            "${cfg.package}/share/diplomacy-bot/init-game.json"
            "game.json"
          ]}
        fi

        chmod 600 game.json

        exec ${lib.escapeShellArg "${cfg.package}/bin/diplomacy-bot"}
      '';
    };
  };
}
