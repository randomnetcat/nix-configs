{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.notifications;

  discordEnabled = cfg.discord.enable;
  mailEnabled = cfg.mail.enable;

  anyEnabled = discordEnabled || mailEnabled;
in
{
  imports = [
    ./fs-keys.nix
  ];

  options = {
    randomcat.notifications = {
      discord = {
        enable = lib.mkEnableOption "automatic failure notifications by discord webhook";

        webhookUrlCredential = config.fountain.lib.mkCredentialOption {
          name= "notify-discord-webhook";
          description = "The wehbhook URL (with token) to use for sending failure notifications.";
        };
      };

      mail = {
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
            default = if cfg.mail.smtp.tls then 465 else 587;
          };

          user = lib.mkOption {
            type = lib.types.str;
            description = "The SMTP user to use";
            default = cfg.mail.sender;
          };

          passwordEncryptedCredentialPath = lib.mkOption {
            type = lib.types.path;
            description = "The path to the encrypted credential file with credential name notify-smtp-password";
          };
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
            --host=${lib.escapeShellArg cfg.mail.smtp.host} \
            --port=${lib.escapeShellArg cfg.mail.smtp.port} \
            ${lib.optionalString cfg.mail.smtp.tls ''
              --tls=on \
              --tls-starttls=off \
              --tls-trust-file=/etc/ssl/certs/ca-certificates.crt \
            ''} \
            --auth=plain \
            --user=${lib.escapeShellArg cfg.mail.smtp.user} \
            --from=${lib.escapeShellArg cfg.mail.sender} \
            --passwordeval="$2" \
            -- \
            "$1"
      '';
    in
    lib.mkIf anyEnabled {
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

      systemd.services."failure-notification@" = lib.mkMerge [
        {
          description = "Send a notification about a failure in %I";
          after = [ "network.target" ];
          before = [ "shutdown.target" ];
          conflicts = [ "shutdown.target" ];

          enableStrictShellChecks = true;

          script = lib.mkBefore ''
            set -eu -o pipefail

            service_name="$1"
            host=${lib.escapeShellArg config.networking.hostName}
          '';

          scriptArgs = "%i";

          unitConfig = {
            DefaultDependencies = false;
          };

          serviceConfig = {
            Type = "oneshot";

            DynamicUser = true;

            # Ensure that the script can read the systemd journal.
            SupplementaryGroups = [
              config.users.groups.systemd-journal.name
            ];

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
        }

        (lib.mkIf cfg.discord.enable {
          script = ''
            send_by_discord() {
              local webhook_url
              webhook_url="$(cat -- "$CREDENTIALS_DIRECTORY"/notify-discord-webhook)"

              local body
              body="$(mktemp)"

              local embed
              embed="$(jq -n '$ARGS.named' \
                --arg title "Service failure" \
                --arg description "The following service has failed: \`$service_name\`." \
                --argjson footer "$(jq -n '$ARGS.named' \
                  --arg text "Host: $host" \
                )" \
                --argjson color 16711680 \
              )"

              jq -n '$ARGS.named' \
                --argjson embeds "$(jq -s <<< "$embed")" \
                > "$body"

              curl -X POST -H "Content-Type: application/json" --data @"$body" -K - <<< "url = \"$webhook_url\""
            }

            send_by_discord || echo "Failed to send notification by Discord." > /dev/stderr
          '';

          path = [
            pkgs.curl
            pkgs.jq
          ];

          serviceConfig = {
            LoadCredentialEncrypted = [
              "notify-discord-webhook:${cfg.discord.webhookUrlCredential}"
            ];
          };
        })

        (lib.mkIf cfg.mail.enable {
          script = ''
            send_by_mail() {
              local logs_file
              logs_file="$(mktemp)"

              journalctl -u "$service_name" -b -n100 > "$logs_file"

              {
                  echo "Subject: [$host] Service failure: $service_name"
                  echo ""
                  echo "The service unit $service_name has failed on host $host. It is currently $(date -u)."
                  echo ""
                  echo "Up to 100 lines of journal context follow:"
                  echo ""
                  cat "$logs_file"
              } | ${notifyScript} ${lib.escapeShellArg cfg.mail.recipient} "cat -- \"\$CREDENTIALS_DIRECTORY/notify-email-password\""
            }

            send_by_mail || echo "Failed to send notification by mail." > /dev/stderr
          '';

          serviceConfig = {
            LoadCredentialEncrypted = [
              "notify-email-password:${cfg.mail.smtp.passwordEncryptedCredentialPath}"
            ];
          };
        })
      ];

      services.zfs.zed = lib.mkIf cfg.mail.enable {
        enableMail = false;

        settings = {
          ZED_EMAIL_ADDR = [ cfg.mail.recipient ];
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

      randomcat.services.fs-keys.zfs-zed-init-creds = lib.mkIf cfg.mail.enable {
        # If this fails, we still want ZED to start.
        wantedBy = [ "zfs-zed.service" ];
        before = [ "zfs-zed.service" ];

        keys.zed-email-password = {
          source.encrypted = {
            path = cfg.mail.smtp.passwordEncryptedCredentialPath;
            credName = "notify-email-password";
          };
        };
      };
    };
}
