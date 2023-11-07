{ config, lib, pkgs, inputs, ... }:

let
  listNames = [
    "agora-discussion"
    "agora-business"
    "agora-official"
  ];

  itemName = "agoranomic";
in {
  systemd.services."archive-agora" = {
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

      StateDirectory = "archive-agora";
      StateDirectoryMode = "700";

      RuntimeDirectory = "archive-agora";
      RuntimeDirectoryMode = "700";

      LoadCredentialEncrypted = "agora-ia-config:${../secrets/agora-ia-config}";
    };

    script = ''
      set -eu -o pipefail
      cd -- "$STATE_DIRECTORY"

      mkdir -p lists
      cd lists

      ${lib.concatLines (map (list: ''
        ${pkgs.wget}/bin/wget -c -- "https://agora:nomic@mailman.agoranomic.org/archives/${list}.mbox"

        ${pkgs.internetarchive}/bin/ia \
          --config-file="$CREDENTIALS_DIRECTORY/agora-ia-config" \
          upload \
          '${itemName}' \
          --remote-name='lists/${list}.mbox' \
          './${list}.mbox'
      '') listNames)}
    '';
  };

  systemd.timers."archive-agora" = {
    wantedBy = [ "multi-user.target" ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
