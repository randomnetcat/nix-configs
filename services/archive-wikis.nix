{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.randomcat.services.archive-wikis;

  credName = "wiki-ia-keys";
  wikiteamPackage = inputs.wikiteam3-nix.packages."${pkgs.hostPlatform.system}".dumpgenerator;

  apisFile = pkgs.writeText "apis.txt" ''
    https://nomic.club/wiki/api.php
    https://infinite.nomic.space/wiki/api.php
    https://wiki.blognomic.com/api.php
  '';
in
{
  options = {
    randomcat.services.archive-wikis = {
      enable = lib.mkEnableOption "service to dump MediaWiki wikis and upload them to the Internet Archive";

      keysCredential = config.fountain.lib.mkCredentialOption {
        name = credName;
        description = "Internet Archive S3 credentials";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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

        LoadCredentialEncrypted = [
          "${credName}:${cfg.keysCredential}"
        ];
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
          "--keysfile=\"\${CREDENTIALS_DIRECTORY}\"/${lib.escapeShellArg credName}"
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
  };
}
