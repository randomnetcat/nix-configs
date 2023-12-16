{ config, lib, pkgs, inputs, ... }:

let
  package = (pkgs.extend inputs.diplomacy-bot.overlay).diplomacy-bot;

  configFile = "${./config.json}";
in
{
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
        "diplomacy-bot-token:${../secrets/diplomacy-bot-token}"
      ];
    };

    script = ''
      set -euo pipefail

      cd -- "$STATE_DIRECTORY"

      ${lib.escapeShellArgs [
        "ln"
        "-sfT"
        "--"
        "${configFile}"
        "config.json"
      ]}

      ln -sfT -- "$CREDENTIALS_DIRECTORY/diplomacy-bot-token" key.txt

      if [ ! -e game.json ]; then
        ${lib.escapeShellArgs [
          "cp"
          "--"
          "${package}/share/diplomacy-bot/init-game.json"
          "game.json"
        ]}
      fi

      chmod 600 game.json

      exec ${lib.escapeShellArg "${package}/bin/diplomacy-bot"}
    '';
  };
}
