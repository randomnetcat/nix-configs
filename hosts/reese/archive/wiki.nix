{ config, lib, pkgs, inputs, ... }:

let
  wikiteamPackage = (pkgs.extend inputs.wikiteam3-nix.overlay).dumpgenerator;
  apisFile = pkgs.writeText "apis.txt" ''
    https://nomic.club/wiki/api.php
    https://infinitenomic.randomcat.org/wiki/api.php
  '';
in
{
  randomcat.secrets.secrets."wiki-ia-keys" = {
    encryptedFile = ../secrets/wiki-ia-keys;
    dest = "/run/keys/wiki-ia-keys";
    owner = "root";
    group = "root";
    permissions = "700";
  };

  systemd.services."archive-wikis" = {
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
      StateDirectory = "archive-wikis";
      StateDirectoryMode = "700";

      LoadCredential="ia-keys:/run/keys/wiki-ia-keys";
    };

    script = ''
      cd -- "$STATE_DIRECTORY"

      set -euo pipefail

      rm -rf work
      mkdir work

      cd work

      ${lib.escapeShellArgs [
        "${wikiteamPackage}/bin/wikiteam-launcher"
        "--7z-path=${pkgs.p7zip}/bin/7z"
        "--generator-arg=--xmlrevisions"
        "--generator-arg=--delay=0"
        "--"
        "${apisFile}"
      ]}

      ${lib.concatStringsSep " " [
        (lib.escapeShellArgs [
          "${wikiteamPackage}/bin/wikiteam-uploader"
          "-u"
          "--logfile=/dev/null"
        ])
        "--keysfile=\"\${CREDENTIALS_DIRECTORY}/ia-keys\""
        (lib.escapeShellArg "${apisFile}")
      ]}
    '';
  };

  systemd.timers."archive-wikis" = {
    wantedBy = [ "multi-user.target" ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
