{ config, lib, pkgs, ... }:

let
  hostKeyCredName = "initrd-host-key";
  hostKeyCredPath = "/boot/randomcat/initrd-host-key";
in
{
  config = {
    boot.initrd.systemd = {
      # We want the ability to order units and the ability to pass credentials
      # to sshd.
      enable = true;

      # The host key credential will be encrypted with the TPM.
      tpm2.enable = true;

      network = {
        enable = true;

        # Reuse existing definitions for these interfaces.
        networks."50-enp3s0" = lib.mkMerge [
         config.systemd.network.networks."50-enp3s0"

         {
           linkConfig.MACAddress = "FE:90:40:66:25:09";
         }
        ];

        networks."50-enp4s0" = lib.mkMerge [
          config.systemd.network.networks."50-enp4s0"

          {
            linkConfig.MACAddress = "6A:83:E5:37:69:FB";
          }
        ];
      };
    };

    boot.initrd.network.ssh = {
      enable = true;

      # Use a different port to prevent host key issues.
      port = 2345;

      # The regular hostKeys option uses initrd secrets to copy a key from the
      # real host filesystem. Instead, we will generate a host key manually
      # such that the normal host never has to see it.
      ignoreEmptyHostKeys = true;

      # Manually add the host key from the systemd credential. This path is
      # guaranteed by systemd.exec(5).
      extraConfig = ''
        HostKey /run/credentials/sshd.service/${hostKeyCredName}
      '';

      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHagOaeTR+/7FL9sErciMw30cmV/VW8HU7J3ZFU5nj9 janet@randomcat.org"
      ];
    };

    # Copy /boot mount from the normal system (either the ESP or XBOOTLDR).
    boot.initrd.systemd.mounts =
      let
        bootFs = config.fileSystems."/boot";
      in
      [
        {
          what = bootFs.device;
          where = "/boot";
          type = bootFs.fsType;
        }
      ];

    boot.initrd.supportedFilesystems = [
      config.fileSystems."/boot".fsType
    ];

    boot.initrd.systemd.services.sshd-init-host-key = {
      after = [ "tpm2.target" ];
      before = [ "sshd.service" "shutdown.target" ];
      wantedBy = [ "sshd.service" ];
      conflicts = [ "shutdown.target" ];

      unitConfig = {
        # To match sshd.
        # See https://github.com/NixOS/nixpkgs/blob/f02fddb8acef29a8b32f10a335d44828d7825b78/nixos/modules/system/boot/initrd-ssh.nix#L350
        DefaultDependencies = false;

        RequiresMountsFor = [
          (dirOf hostKeyCredPath)
        ];
      };

      serviceConfig = {
        Type = "oneshot";
      };

      script = ''
        HOST_KEY_CRED=${lib.escapeShellArg hostKeyCredPath}

        if [ ! -d /boot ]; then
          echo "Cannot store SSH host key in /boot because /boot does not exist or is not a directory"
          exit 1
        fi

        if [ ! -f "$HOST_KEY_CRED" ]; then
          mkdir -p -- "$(dirname -- "$HOST_KEY_CRED")"

          WORK="$(mktemp -d)"

          cleanup() {
            rm -r -- "$WORK"
          }

          trap cleanup EXIT

          # initrd ssh uses the same ssh package as the regular system.
          # See https://github.com/NixOS/nixpkgs/blob/3f0a8ac25fb674611b98089ca3a5dd6480175751/nixos/modules/system/boot/initrd-ssh.nix#L14
          ${lib.getExe' config.programs.ssh.package "ssh-keygen"} -N "" -t ed25519 -f "$WORK/host-key"

          # Store the host key on the ESP (or XBOOTLDR if it exists). This is
          # encrypted only with the TPM key (which the initrd has access to).
          ${lib.getExe' config.boot.initrd.systemd.package "systemd-creds"} encrypt --with-key=tpm2 --name=${lib.escapeShellArg hostKeyCredName} -- "$WORK/host-key" "$HOST_KEY_CRED"
        fi
      '';
    };

    # Ensure that the two executables used above are actually in the initrd.
    boot.initrd.systemd.storePaths = [
      (lib.getExe' config.programs.ssh.package "ssh-keygen")
      (lib.getExe' config.boot.initrd.systemd.package "systemd-creds")
    ];

    boot.initrd.systemd.services.sshd = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          "${hostKeyCredName}:${hostKeyCredPath}"
        ];
      };
    };

    boot.initrd.kernelModules = [
      # Required for network card
      "r8169"
    ];
  };
}
