{ pkgs, lib, utils, config, options, ... }:

let
  types = lib.types;
  cfg = config.services.randomcat.agorabot-server;
  secretConfigModule = { name, ... }: {
    options = {
      encryptedFile = lib.mkOption {
        type = types.path;
      };
    };
  };
  extraConfigModule = { name, ... }: {
    options = {
      text = lib.mkOption {
        type = types.str;
      };
    };
  };
  instancesModule = { name, ... }: {
    options = {
      package = lib.mkOption {
        type = types.package;
      };

      configSource = lib.mkOption {
        type = types.path;
      };

      dataVersion = lib.mkOption {
        type = types.int;
      };

      tokenEncryptedFile = lib.mkOption {
        type = types.path;
        description = "Path to encrypted bot token.";
      };

      secretConfigFiles = lib.mkOption {
        type = types.attrsOf (types.submodule secretConfigModule);
        default = {};
      };

      extraConfigFiles = lib.mkOption {
        type = types.attrsOf (types.submodule extraConfigModule);
        default = {};
      };
    };
  };
in
{
  imports = [
    ../agorabot
  ];

  options = {
    services.randomcat.agorabot-server = {
      enable = lib.mkEnableOption {
        name = "AgoraBot server";
      };

      user = lib.mkOption {
        type = types.str;
        description = "Name of the user for AgoraBot instances. If not set to the default, the user must be separately configured.";
        default = "agorabot";
      };

      group = lib.mkOption {
        type = types.str;
        description = "Name of the group for AgoraBot instances. If not set to the default, the group must be separately configured.";
        default = "agorabot";
      };

      instances = lib.mkOption {
        type = types.attrsOf (types.submodule instancesModule);
        default = {};
      };
    };
  };

  config =
    let
      tokenKeyNameOf = instance: "agorabot-discord-token-${instance}";
      escapeSecretConfigPath = path: utils.escapeSystemdPath path;
      secretConfigKeyName = { instance, secretPath }: "agorabot-config-${instance}-${escapeSecretConfigPath secretPath}";

      baseAgoraBotUserConfig = {
        users.users = {
          agorabot = {
            extraGroups = [ "keys" ];
          };
        };
      };

      tokenKeyConfigOf = instanceName: instanceValue: let keyName = tokenKeyNameOf instanceName; in {
        "${keyName}" = {
          encryptedFile = instanceValue.tokenEncryptedFile;
          dest = "/run/keys/${keyName}";
          owner = cfg.user;
          group = cfg.group;
          permissions = "0640";
        };
      };

      makeSecretConfigKeyConfig = { instance, secretPath, localEncryptedFile }:
        let
          keyName = secretConfigKeyName { inherit instance secretPath; };
        in
        {
          "${keyName}" = {
            encryptedFile = localEncryptedFile;
            dest = "/run/keys/${keyName}";
            owner = cfg.user;
            group = cfg.group;
            permissions = "0640";
          };
        };

      makeKeysConfig = name: value: lib.mkMerge (
          (lib.singleton (tokenKeyConfigOf name value)) ++
          (lib.mapAttrsToList (secretPath: secretValue: makeSecretConfigKeyConfig { instance = name; inherit secretPath; localEncryptedFile = secretValue.encryptedFile; }) value.secretConfigFiles)
      );

      makeAgoraBotInstanceConfig = name: value:
        {
          "${name}" = {
            inherit (value) package dataVersion;

            tokenFilePath = "/run/keys/${tokenKeyNameOf name}";

            configGeneratorPackage =
              let
                copySecretConfigFiles =
                  lib.concatStringsSep
                    "\n"
                    (
                      map
                        (secretPath:
                          let
                            keyName = secretConfigKeyName { instance = name; inherit secretPath; };
                          in
                          ''cp --no-preserve=mode -- ${lib.escapeShellArg "/run/keys/${keyName}"} "$1"/${lib.escapeShellArg secretPath}''
                        )
                        (builtins.attrNames value.secretConfigFiles)
                    )
                ;
                generateExtraConfigFiles =
                  lib.concatStringsSep
                    "\n"
                    (
                      lib.mapAttrsToList
                        (configPath: configValue:
                          ''printf "%s" ${pkgs.lib.escapeShellArg configValue.text} > "$1"/${lib.escapeShellArg configPath}''
                        )
                        value.extraConfigFiles
                    );
              in
              pkgs.writeShellScriptBin "generate-config" ''
                set -eu
                set -o pipefail

                if [ "$#" -lt "1" ]; then
                  exit 1
                fi

                cp -RT --no-preserve=mode -- ${pkgs.lib.escapeShellArg "${value.configSource}"} "$1"

                ${copySecretConfigFiles}
                ${generateExtraConfigFiles}
              '';

            user = cfg.user;
            group = cfg.group;
          };
        };

        makeSystemdServicesConfig = name: value: {
          "agorabot-instance-${name}" = {
            serviceConfig = {
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
            };
          };
        };
    in
    lib.mkIf (cfg.enable) (lib.mkMerge [
      (lib.mkIf (cfg.user == "agorabot" && cfg.instances != {}) baseAgoraBotUserConfig)
      {
        randomcat.secrets.secrets = lib.mkMerge (lib.mapAttrsToList makeKeysConfig cfg.instances);
        services.randomcat.agorabot.instances = lib.mkMerge (lib.mapAttrsToList makeAgoraBotInstanceConfig cfg.instances);
        systemd.services = lib.mkMerge (lib.mapAttrsToList makeSystemdServicesConfig cfg.instances);
      }
    ]);
}
