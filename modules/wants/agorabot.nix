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

      tokenFilePath = lib.mkOption {
        type = types.str;
        description = "Path to a file containing the bot token.";
      };

      unit = {
        wantedBy = lib.mkOption {
          type = types.listOf types.str;
          default = [ "multi-user.target" ];
        };

        after = lib.mkOption {
          type = types.listOf types.str;
          default = [ "network.target" ];
        };

        wants = lib.mkOption {
          type = types.listOf types.str;
          default = [];
        };

        description = lib.mkOption {
          type = types.str;
          default = "AgoraBot instance ${name}";
        };

        auth = {
          user = lib.mkOption {
            type = types.str;
            description = "Name of the user under which to run the bot.";
            default = "root";
          };

          group = lib.mkOption {
            type = types.str;
            description = "Name of the group under which to run the bot.";
            default = "root";
          };
        };

      };
      
      workingDir = lib.mkOption {
        type = types.str;
        description = "Working directory of the bot.";
      };

      autoRestart.enable = lib.mkEnableOption "Auto restart";
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
    systemd.services = lib.mapAttrs' (
      name: value:
      {
        name = "agorabot-instance-${name}";

        value = {
          enable = true;

          inherit (value.unit) wantedBy wants after description;

          serviceConfig = {
            User = value.unit.auth.user;
            Group = value.unit.auth.user;
            Restart = "on-failure";
            WorkingDirectory = value.workingDir;
            RestartSec = "30s";
          } // lib.optionalAttrs value.autoRestart.enable {
            Restart = "always";
          };

          script = ''
            rm -rf -- ${lib.escapeShellArg "${value.workingDir}/generated-config"}
            mkdir -- ${lib.escapeShellArg "${value.workingDir}/generated-config"}
            ${value.configGeneratorPackage}/bin/generate-config ${lib.escapeShellArg "${value.workingDir}/generated-config"}

            ${lib.escapeShellArg "${value.package}/bin/AgoraBot"} \
              --token "$(cat ${lib.escapeShellArg value.tokenFilePath})" \
              --data-version ${lib.escapeShellArg "${builtins.toString value.dataVersion}"} \
              --config-path ${lib.escapeShellArg "${value.workingDir}/generated-config"} \
              --storage-path ${lib.escapeShellArg "${value.workingDir}/storage"} \
              --temp-path ${lib.escapeShellArg "${value.workingDir}/tmp"}
          '';
        };
      }
    ) cfg.instances;
  };
}
