{ config, lib, pkgs, inputs, ... }:

let
  package = (pkgs.extend inputs.diplomacy-bot.overlay).diplomacy-bot;

  configFile = "${./config.json}";
in
{
  randomcat.secrets.secrets."diplomacy-bot-token" = {
    encryptedFile = ../secrets/diplomacy-bot-token;
    dest = "/run/keys/diplomacy-bot-token";
    owner = "root";
    group = "root";
    permissions = "700";
  };

  systemd.services."diplomacy-bot" = {
    wantedBy = [ "multi-user.target" ];

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

      LoadCredential="token:/run/keys/diplomacy-bot-token";
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

      ln -sfT -- "$CREDENTIALS_DIRECTORY/token" key.txt

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
