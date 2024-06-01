{ config, options, lib, pkgs, utils, ... }:

let
  types = lib.types;

  credRegex = "[a-zA-Z0-9_\\-]+";

  keySubmodule = types.submodule ({ name, ... }: {
    options = {
      dest = lib.mkOption {
        type = types.str;
        description = "The location that the credential will be placed on disk.";
        default = if lib.hasPrefix "/" name then name else "/run/keys/${name}";
      };

      source = lib.mkOption {
        type = types.attrTag {
          encrypted = lib.mkOption {
            type = types.submodule ({
              options = {
                path = lib.mkOption {
                  type = types.path;
                  description = "The systemd-encrypted credential file.";
                };

                credName = lib.mkOption {
                  type = types.strMatching credRegex;
                  description = "iThe name encoded in the credential file (much match the name the file was encrypted with).";
                };
              };

              config = {
                credName = lib.mkIf (!(lib.hasInfix "/" name)) (lib.mkDefault name);
              };
            });
          };

          inherited = lib.mkOption {
            type = types.either (types.enum [ true ]) (types.strMatching credRegex);
            description = ''
              The name of the credential to inherit from the system service manager (e.g. with systemd-nspawn's
              `--load-credential` or `--set-credential`). 
            '';
            apply = v: if v == true then name else v;
          };
        };
      };

      mode = lib.mkOption {
        type = types.strMatching "[0-7]{3,4}";
        description = "The mode of the file";
        default = "0640";
      };

      user = lib.mkOption {
        type = types.passwdEntry types.str;
        description = "The owner of the file";
        default = config.users.users.root.name;
      };

      group = lib.mkOption {
        type = types.passwdEntry types.str;
        description = "The group of the file";
        default = config.users.groups.keys.name;
      };
    };
  });

  serviceSubmodule = types.submodule ({ name, ... }: {
    options =
      let
        mkServiceOption = name: lib.mkOption {
          type = types.listOf types.str;
          description = "See `systemd.services.*.${name}`";
          default = [];
        };
      in
      {
        keys = lib.mkOption {
          type = types.attrsOf keySubmodule;
          description = "Configuration for the credentials to add to the filesystem.";
        };

        wantedBy = mkServiceOption "wantedBy";
        requiredBy = mkServiceOption "requiredBy";
        before = mkServiceOption "before";

        name = lib.mkOption {
          type = types.str;
          description = "Name of the systemd service";
          default = name;
        };
      };
  });
in
{
  options = {
    randomcat.services.fs-keys = lib.mkOption {
      type = types.attrsOf serviceSubmodule;
      description = "Configuration for services that place systemd credentials into paths in the filesystem.";
    };
  };

  config = {
    systemd.services = lib.mapAttrs' (_: serviceCfg: {
      name = serviceCfg.name;

      value =
        let
          keys = serviceCfg.keys;

          rawInheritedCreds = lib.sortOn (k: k.dest) (lib.filter (k: k.source ? inherited) (lib.attrValues keys));

          inheritedCreds = lib.imap0 (i: k: {
            localName = "inherited-${toString i}";
            config = k.value;
          }) rawInheritedCreds;

          encryptedCreds = lib.sortOn (k: k.dest) (lib.filter (k: k.source ? encrypted) (lib.attrValues keys));
        in
        {
          inherit (serviceCfg) wantedBy requiredBy before;

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;

            PrivateMounts = true;
            PrivateTmp = true;
            UMask = "077";

            WorkingDirectory = "/var/empty";
            RuntimeDirectory = "fs-keys/${serviceCfg.name}";
            RuntimeDirectoryMode = "0700";

            LoadCredential = map (k: "${k.localName}:${k.config.source.inherited}") inheritedCreds;
          };

          unitConfig = {
            RequiresMountsFor = map (k: builtins.dirOf k.dest) (lib.attrValues keys);
          };

          script = ''
            set -euo pipefail

            # Mount a ramfs for storing credentials before movement.
            # Don't need to clean this up due to PrivateMounts=true.
            WORK_DIR="$RUNTIME_DIRECTORY"/creds
            mkdir -- "$WORK_DIR"
            ${lib.getExe' pkgs.util-linux "mount"} -t ramfs -o mode=0700,uid=0,gid=0 -- ramfs "$WORK_DIR"

            install_cred() {
              SRC="$1"
              DEST="$2"
              MODE="$3"
              USER="$4"
              GROUP="$5"

              chmod -- "$MODE" "$SRC"
              chown -- "$USER:$GROUP" "$SRC"
              mv -T -- "$SRC" "$DEST"
            }

            load_inherited() {
              CRED_NAME="$1"
              DEST="$2"
              MODE="$3"
              USER="$4"
              GROUP="$5"

              WORK_FILE="$WORK_DIR/tmp-$CRED_NAME"

              cp -T -- "$CREDENTIALS_DIRECTORY/$CRED_NAME" "$SRC"
              install_cred "$WORK_FILE" "$DEST" "$MODE" "$USER" "$GROUP"
            }

            load_encrypted() {
              ENCRYPTED_SRC="$1"
              CRED_NAME="$2"
              DEST="$3"
              MODE="$4"
              USER="$5"
              GROUP="$6"

              WORK_FILE="$WORK_DIR/tmp-$CRED_NAME"

              systemd-creds --name="$CRED_NAME" -- decrypt "$ENCRYPTED_SRC" "$WORK_FILE"
              install_cred "$WORK_FILE" "$DEST" "$MODE" "$USER" "$GROUP"
            }

            ${lib.concatMapStringsSep "\n" (k: lib.escapeShellArgs [
              "load_inherited"
              k.localName
              k.config.dest
              k.config.mode
              k.config.user
              k.config.group
            ]) inheritedCreds}

            ${lib.concatMapStringsSep "\n" (k: lib.escapeShellArgs [
              "load_encrypted"
              k.source.encrypted.path
              k.source.encrypted.credName
              k.dest
              k.mode
              k.user
              k.group
            ]) encryptedCreds}
          '';
        };
    }) config.randomcat.services.fs-keys;
  };
}
