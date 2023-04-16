{ pkgs, lib, utils, config, options, ... }:

let
  types = lib.types;
  cfg = config.randomcat.services.agorabot-server;
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
    randomcat.services.agorabot-server = {
      enable = lib.mkEnableOption {
        name = "AgoraBot server";
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
      tokenCredName = "token";
      escapeSecretConfigPath = path: utils.escapeSystemdPath path;
      secretConfigExternalKeyName = { instance, secretPath }: "agorabot-config-${instance}-${escapeSecretConfigPath secretPath}";
      secretConfigInternalCredName = args: "config-" + (builtins.hashString "sha256" (secretConfigExternalKeyName args));

      tokenKeyConfigOf = instanceName: instanceValue: let keyName = tokenKeyNameOf instanceName; in {
        "${keyName}" = {
          encryptedFile = instanceValue.tokenEncryptedFile;
          dest = "/run/keys/${keyName}";
          owner = "root";
          group = "root";
          permissions = "0640";
        };
      };

      makeSecretConfigKeyConfig = { instance, secretPath, localEncryptedFile }:
        let
          keyName = secretConfigExternalKeyName { inherit instance secretPath; };
        in
        {
          "${keyName}" = {
            encryptedFile = localEncryptedFile;
            dest = "/run/keys/${keyName}";
            owner = "root";
            group = "root";
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

            tokenPath = "\"$CREDENTIALS_DIRECTORY\"/${lib.escapeShellArg tokenCredName}";

            configGeneratorPackage =
              let
                copySecretConfigFiles =
                  lib.concatStringsSep
                    "\n"
                    (
                      map
                        (secretPath:
                          let
                            credName = secretConfigInternalCredName { instance = name; inherit secretPath; };
                          in
                          ''
                            mkdir -p -- "$(dirname -- "$1"/${lib.escapeShellArg secretPath})"
                            ln -s -- "''${CREDENTIALS_DIRECTORY}"/${lib.escapeShellArg credName} "$1"/${lib.escapeShellArg secretPath}
                          ''
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
                          ''
                            mkdir -p -- "$(dirname -- "$1"/${lib.escapeShellArg configPath})"
                            printf "%s" ${pkgs.lib.escapeShellArg configValue.text} > "$1"/${lib.escapeShellArg configPath}
                          ''
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
          };
        };

        makeSystemdServicesConfig = instanceName: value: {
          "agorabot-instance-${instanceName}" = {
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
              # UMask = "077"; # Causes errors in mkdir call
              SystemCallArchitectures = "native";
              LoadCredential =
                map
                (secretPath:
                  let
                    args = { instance = instanceName; inherit secretPath; };
                    credName = secretConfigInternalCredName args;
                    keyName = secretConfigExternalKeyName args;
                  in
                  "${credName}:/run/keys/${keyName}"
                )
                (builtins.attrNames value.secretConfigFiles)
                ++ [
                  "${tokenCredName}:/run/keys/${tokenKeyNameOf instanceName}"
                ];
            };
          };
        };
    in
    lib.mkIf (cfg.enable) (lib.mkMerge [
      {
        randomcat.secrets.secrets = lib.mkMerge (lib.mapAttrsToList makeKeysConfig cfg.instances);
        randomcat.services.agorabot.instances = lib.mkMerge (lib.mapAttrsToList makeAgoraBotInstanceConfig cfg.instances);
        systemd.services = lib.mkMerge (lib.mapAttrsToList makeSystemdServicesConfig cfg.instances);
      }
    ]);
}
