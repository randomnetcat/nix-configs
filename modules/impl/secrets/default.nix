# Shameless stolen from https://christine.website/blog/nixos-encrypted-secrets-2021-01-20

{ config, pkgs, lib, ... }:

let
  types = lib.types;
  cfg = config.randomcat.secrets;

  secret = types.submodule {
    options = {
      content = lib.mkOption {
        type = types.str;
        description = "secret content";
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

  mkSecretOnDisk = name: { content }:
    let key = cfg.sshPubKey; in
    pkgs.runCommand
      "encrypted-secret-${name}"
      {
        inherit content;
        passAsFile = [ "content" ];
      }
      ''
        mv "$contentPath" secret.bin
        ${lib.escapeShellArg "${pkgs.age}/bin/age"} -a -r ${lib.escapeShellArg cfg.sshPubKey} -o "$out" secret.bin
      '';

  mkService = name: { content, dest, owner, group, permissions }: {
    description = "decrypt secret for ${name}";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = let escapedDest = lib.escapeShellArg "${dest}"; in ''
      rm -rf -- ${escapedDest}
      (umask 777; touch -- ${escapedDest})
      chown ${owner}:${group} -- ${escapedDest}
      chmod ${permissions} -- ${escapedDest}
      ${pkgs.age}/bin/age -d -i ${lib.escapeShellArg cfg.sshPrivKeyLocation} ${
        mkSecretOnDisk name { inherit content; }
      } > ${escapedDest}
    '';
  };
in
{
  options.randomcat.secrets.sshPubKey = lib.mkOption {
    type = types.str;
    description = "ssh public key to encrypt secret with";
  };

  options.randomcat.secrets.sshPrivKeyLocation = lib.mkOption {
    type = types.str;
    description = "location of the ssh private key on the target machine";
    default = "/etc/ssh/ssh_host_ed25519_key";
  };

  options.randomcat.secrets.secrets = lib.mkOption {
    type = types.attrsOf secret;
    description = "secret configuration";
    default = {};
  };

  config.systemd.services =
    let
      units = lib.mapAttrs' (name: info: {
        name = "${name}-key";
        value = (mkService name info);
      }) cfg.secrets;
    in
    units;
}
