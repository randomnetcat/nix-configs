# Shameless stolen from https://christine.website/blog/nixos-encrypted-secrets-2021-01-20

{ config, pkgs, lib, ... }:

let
  types = lib.types;
  cfg = config.randomcat.secrets;

  secret = types.submodule {
    options = {
      encryptedFile = lib.mkOption {
        type = types.path;
        description = "path to encrypted secret (on build machine)";
      };

      dest = lib.mkOption {
        type = types.str;
        description = "where to write the decrypted secret to";
      };

      owner = lib.mkOption {
        default = "root";
        type = types.str;
        description = "who should own the secret";
      };

      group = lib.mkOption {
        default = "root";
        type = types.str;
        description = "what group should own the secret";
      };

      permissions = lib.mkOption {
        default = "0400";
        type = types.str;
        description = "Permissions expressed as octal.";
      };
    };
  };
in
{
  options.randomcat.secrets.secrets = lib.mkOption {
    type = types.attrsOf secret;
    description = "secret configuration";
    default = {};
  };

  config.age.secrets = lib.mapAttrs' (name: info: {
    name = "${name}";
    value = {
      file = info.encryptedFile;
      path = info.dest;
      mode = info.permissions;
      owner = info.owner;
      group = info.group;
    };
  }) cfg.secrets;
}
