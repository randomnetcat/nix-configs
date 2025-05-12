{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.notifications.mail;
in
{
  imports = [
    ./fs-keys.nix
  ];

  options = {
    randomcat.notifications.mail = {
      enable = lib.mkEnableOption "automatic failure notifications by email";

      sender = lib.mkOption {
        type = lib.types.str;
        description = "The email address that notifications are sent from";
        example = "foo@example.com";
      };

      recipient = lib.mkOption {
        type = lib.types.str;
        description = "The email address that notifications are sent to";
        example = "foo@example.com";
      };

      smtp = {
        host = lib.mkOption {
          type = lib.types.str;
          description = "The SMTP host to connect to";
          example = "mail.gmail.com";
          default = "mail.unspecified.systems";
        };

        tls = lib.mkOption {
          type = lib.types.bool;
          description = "Whether to use SMTP over TLS";
          default = true;
        };

        port = lib.mkOption {
          type = lib.types.port;
          description = "The SMTP port to connect to";
        };

        user = lib.mkOption {
          type = lib.types.str;
          description = "The SMTP user to use";
        };

        passwordEncryptedCredentialPath = lib.mkOption {
          type = lib.types.path;
          description = "The path to the encrypted credential file with credential name notify-smtp-password";
        };
      };
    };
  };

  config =
    let
      # Arguments: recipient password-script
      # Stdin: email content
      # 
      # password-script is a string that, when eval-ed, prints the SMTP password on stdout.
      notifyScript = pkgs.writeShellScript "notify-sendmail" ''
        exec ${lib.escapeShellArg "${pkgs.msmtp}/bin/msmtp"} \
            --host=${lib.escapeShellArg cfg.smtp.host} \
            --port=${lib.escapeShellArg cfg.smtp.port} \
            ${lib.optionalString cfg.smtp.tls ''
              --tls=on \
              --tls-starttls=off \
              --tls-trust-file=/etc/ssl/certs/ca-certificates.crt \
            ''} \
            --auth=plain \
            --user=${lib.escapeShellArg cfg.smtp.user} \
            --from=${lib.escapeShellArg cfg.sender} \
            --passwordeval="$2" \
            -- \
            "$1"
      '';
    in
    lib.mkIf cfg.enable {
      randomcat.notifications.mail.smtp.user = lib.mkDefault cfg.sender;
      randomcat.notifications.mail.smtp.port = lib.mkDefault (if cfg.smtp.tls then 465 else 587);

      services.zfs.zed = {
        enableMail = false;

        settings = {
          ZED_EMAIL_ADDR = [ cfg.recipient ];
          ZED_EMAIL_OPTS = "'@ADDRESS@' '@SUBJECT@'";

          ZED_NOTIFY_INTERVAL_SECS = 3600;
          ZED_NOTIFY_VERBOSE = true;

          ZED_USE_ENCLOSURE_LEDS = true;
          ZED_SCRUB_AFTER_RESILVER = true;

          ZED_EMAIL_PROG = "${pkgs.writeShellScript "zed-sendmail" ''
            set -euo pipefail

            {
                echo "Subject: $2"
                echo ""
                cat
            } | ${notifyScript} "$1" "cat /run/keys/zed-email-password"
          ''}";
        };
      };

      randomcat.services.fs-keys.zfs-zed-init-creds = {
        # If this fails, we still want ZED to start.
        wantedBy = [ "zfs-zed.service" ];
        before = [ "zfs-zed.service" ];

        keys.zed-email-password = {
          source.encrypted = {
            path = cfg.smtp.passwordEncryptedCredentialPath;
            credName = "notify-email-password";
          };
        };
      };

      systemd.packages = [
        (pkgs.linkFarm "failure-notification-overrides" [
          {
            name = "etc/systemd/system/service.d/90-toplevel-failure-notification.conf";
            path = pkgs.writeText "90-toplevel-failure-notification.conf" ''
              [Unit]
              OnFailure=failure-notification@%n
            '';
          }

          # Prevent recursion of failure-notification@.service
          {
            name = "etc/systemd/system/failure-notification@.service.d/90-toplevel-failure-notification.conf";
            path = pkgs.emptyFile;
          }
        ])
      ];

      systemd.services."failure-notification@" = {
        description = "Send a notification about a failure in %I";
        after = [ "network.target" ];
        before = [ "shutdown.target" ];
        conflicts = [ "shutdown.target" ];

        unitConfig = {
          DefaultDependencies = false;
        };

        serviceConfig =
          let
            gatherJournal = pkgs.writeShellScript "failure-gather-journal" ''
              set -euo pipefail

              journalctl -u "$1" -b -n100 > "$RUNTIME_DIRECTORY/log"

              # Access to file is protected by RuntimeDirectoryMode
              chmod 0444 -- "$RUNTIME_DIRECTORY/log"
            '';

            escapedHost = lib.escapeShellArg config.networking.hostName;

            sendNotification = pkgs.writeShellScript "failure-send-notification" ''
              set -euo pipefail

              {
                  echo "Subject: ["${escapedHost}"] Service failure: $1"
                  echo ""
                  echo "The service unit $1 has failed on host "${escapedHost}". It is currently $(date -u)."
                  echo ""
                  echo "Up to 100 lines of journal context follow:"
                  echo ""
                  cat "$RUNTIME_DIRECTORY/log"
              } | ${notifyScript} ${lib.escapeShellArg cfg.recipient} "cat -- \"\$CREDENTIALS_DIRECTORY/notify-email-password\""
            '';
          in
          {
            Type = "oneshot";

            LoadCredentialEncrypted = [
              "notify-email-password:${cfg.smtp.passwordEncryptedCredentialPath}"
            ];

            ExecStart = [
              "+${gatherJournal} %i" # Need root in order to read journal
              "${sendNotification} %i"
            ];

            RuntimeDirectory = "notify-failure/%i";
            RuntimeDirectoryMode = "0700";

            DynamicUser = true;

            CapabilityBoundingSet = "";
            LockPersonality = true;
            PrivateDevices = true;
            PrivateUsers = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            RestrictNamespaces = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [ "@system-service" "~@privileged @resources" ];
          };
      };
    };
}
