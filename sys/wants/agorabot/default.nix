{ pkgs, config, lib, utils, ... }:

let
  types = lib.types;
  cfg = config.randomcat.services.agorabot;

  secretConfigModule = { ... }: {
    options = {
      credFile = lib.mkOption {
        type = types.path;
      };
    };
  };

  extraConfigModule = { ... }: {
    options = {
      text = lib.mkOption {
        type = types.str;
      };
    };
  };

  instancesModule = { ... }: {
    options = {
      enable = lib.mkEnableOption {
        name = "AgoraBot server instance";
      };

      package = lib.mkOption {
        type = types.package;
      };

      dataVersion = lib.mkOption {
        type = types.int;
      };

      configSource = lib.mkOption {
        type = types.path;
      };

      tokenCredFile = lib.mkOption {
        type = types.path;
        description = "Path to systemd encrypted bot token credential";
      };

      secretConfig = lib.mkOption {
        type = types.attrsOf (types.submodule secretConfigModule);
        default = {};
      };

      extraConfig = lib.mkOption {
        type = types.attrsOf (types.submodule extraConfigModule);
        default = {};
      };
    };
  };

  escapeSecretConfigPath = path: utils.escapeSystemdPath path;
  secretConfigCredName = { instance, secretPath }: "agorabot-${instance}-config-${escapeSecretConfigPath secretPath}";
in
{
  options = {
    randomcat.services.agorabot = {
      instances = lib.mkOption {
        type = types.attrsOf (types.submodule instancesModule);
        default = {};
      };
    };
  };

  config = {
    systemd.targets.agorabot = lib.mkIf (lib.any (value: value.enable) (lib.attrValues cfg.instances)) {
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services = lib.mapAttrs' (
      name: value:
      {
        name = "agorabot-${name}";

        value = lib.mkIf value.enable {
          description = "AgoraBot instance ${name}";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          wantedBy = [ "agorabot.target" ];

          serviceConfig = {
            DynamicUser = true;
            Restart = "on-failure";
            RestartSec = "30s";
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
            SystemCallArchitectures = "native";

            RuntimeDirectory = "agorabot/${name}";
            RuntimeDirectoryMode = "700";
            StateDirectory = "agorabot/${name}";
            StateDirectoryMode = "700";

            LoadCredentialEncrypted = [
              "agorabot-${name}-token:${value.tokenCredFile}"
            ] ++ lib.mapAttrsToList (secretPath: secretValue: "${secretConfigCredName { instance = name; inherit secretPath; }}:${secretValue.credFile}") value.secretConfig;
          };

          script =
            let
              generateExtraConfigFiles =
                lib.concatStringsSep
                  "\n"
                  (
                    lib.mapAttrsToList
                      (configPath: configValue:
                        ''
                          mkdir -p -- "$(dirname -- "$BOT_CONFIG_DIR"/${lib.escapeShellArg configPath})"
                          printf "%s" ${lib.escapeShellArg configValue.text} > "$BOT_CONFIG_DIR"/${lib.escapeShellArg configPath}
                        ''
                      )
                      value.extraConfig
                  );

              copySecretConfigFiles =
                lib.concatStringsSep
                  "\n"
                  (
                    map
                      (secretPath:
                        let
                          credName = secretConfigCredName { instance = name; inherit secretPath; };
                        in
                        ''
                          mkdir -p -- "$(dirname -- "$BOT_CONFIG_DIR"/${lib.escapeShellArg secretPath})"
                          ln -s -- "''${CREDENTIALS_DIRECTORY}"/${lib.escapeShellArg credName} "$BOT_CONFIG_DIR"/${lib.escapeShellArg secretPath}
                        ''
                      )
                      (lib.attrNames value.secretConfig)
                  );
            in

            ''
              set -euo pipefail

              BOT_CONFIG_DIR="$RUNTIME_DIRECTORY/generated-config"

              # Base config
              cp -RT --no-preserve=mode -- ${lib.escapeShellArg "${value.configSource}"} "$BOT_CONFIG_DIR"

              # Secret config
              ${copySecretConfigFiles}

              # Extra config
              ${generateExtraConfigFiles}

              # Set config modes because some external programs care about this
              chmod -R 700 -- "$BOT_CONFIG_DIR"
              find "$BOT_CONFIG_DIR" -type f -exec chmod 600 -- {} +

              BOT_STORAGE_DIR="$STATE_DIRECTORY/storage"
              mkdir -p -m 700 -- "$BOT_STORAGE_DIR"

              BOT_TMP_DIR="$STATE_DIRECTORY/tmp"
              rm -rf -- "$BOT_TMP_DIR"
              mkdir -m 700 -- "$BOT_TMP_DIR"

              exec ${lib.escapeShellArg "${value.package}/bin/AgoraBot"} \
                --token-path "''${CREDENTIALS_DIRECTORY}"/${lib.escapeShellArg "agorabot-${name}-token"} \
                --data-version ${lib.escapeShellArg "${toString value.dataVersion}"} \
                --config-path "$BOT_CONFIG_DIR" \
                --storage-path "$BOT_STORAGE_DIR" \
                --temp-path "$BOT_TMP_DIR"
            '';
        };
      }
    ) cfg.instances;
  };
}
