{ pkgs, config,  ... }:

let
  lib = pkgs.lib;
  types = lib.types;
  cfg = config.services.randomcat.agorabot;
  instancesModule = { name, ... }: {
    options = {
      package = lib.mkOption {
        type = types.package;
      };

      configGeneratorPackage = lib.mkOption {
        type = types.package;
        description = "Package with script to generate config directory. The script should be in bin/generate-config in the output, and should accept a single argument (the directory to put the generated config in).";
      };

      dataVersion = lib.mkOption {
        type = types.int;
      };

      tokenGeneratorPackage = lib.mkOption {
        type = types.package;
        description = "Package with script to generate bot token. The script should be in bin/generate-token in the output, should accept no arguments, and should print the token to stdout.";
      };

      restartOnHalt = lib.mkOption {
        type = types.bool;
        description = "Whether to restart the bot when a clean shutdown is initiated (probably by !halt).";
        default = true;
      };
   };
  };
in
{
  options = {
    services.randomcat.agorabot = {
      instances = lib.mkOption {
        type = types.attrsOf (types.submodule instancesModule);
        default = {};
      };
    };
  };

  config = {
    systemd.targets.agorabot-instances = {
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services = lib.mapAttrs' (
      name: value:
      {
        name = "agorabot-instance-${name}";

        value = {
          description = "AgoraBot instance ${name}";
          after = [ "network-online.target" ];
          wantedBy = [ "agorabot-instances.target" ];

          serviceConfig = {
            DynamicUser = true;
            Restart = if value.restartOnHalt then "always" else "on-failure";
            RestartSec = "30s";
            RuntimeDirectory="agorabot/${name}";
            RuntimeDirectoryMode = "700";
            StateDirectory="agorabot/${name}";
            StateDirectoryMode = "700";
          };

          script = ''
            set -euo pipefail

            BOT_CONFIG_DIR="$RUNTIME_DIRECTORY/generated-config"
            ${lib.escapeShellArg "${value.configGeneratorPackage}/bin/generate-config"} "$BOT_CONFIG_DIR"

            BOT_TOKEN="$(${lib.escapeShellArg "${value.tokenGeneratorPackage}/bin/generate-token"})"

            BOT_STORAGE_DIR="$STATE_DIRECTORY/storage"
            mkdir -p -m 700 -- "$BOT_STORAGE_DIR"

            BOT_TMP_DIR="$STATE_DIRECTORY/tmp"
            rm -rf -- "$BOT_TMP_DIR"
            mkdir -m 700 -- "$BOT_TMP_DIR"

            exec ${lib.escapeShellArg "${value.package}/bin/AgoraBot"} \
              --token "$BOT_TOKEN" \
              --data-version ${lib.escapeShellArg "${builtins.toString value.dataVersion}"} \
              --config-path "$BOT_CONFIG_DIR" \
              --storage-path "$BOT_STORAGE_DIR" \
              --temp-path "$BOT_TMP_DIR"
          '';
        };
      }
    ) cfg.instances;
  };
}
