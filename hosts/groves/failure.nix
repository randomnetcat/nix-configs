{ config, lib, pkgs, ... }:

{
  config = {
    systemd.packages = [
      (pkgs.linkFarm "failure-notification-overrides" [
        {
          name = "etc/systemd/system/service.d/90-toplevel-failure-notification.conf";
          path = pkgs.writeText "90-toplevel-failure-notification.conf" ''
            [Unit]
            OnFailure=failure-notification@%n
          '';
        }

        # Prevent recursion of failure-notification#.service
        {
          name = "etc/systemd/system/failure-notification@.service.d/90-toplevel-failure-notification.conf";
          path = pkgs.emptyFile;
        }
      ])
    ];

    systemd.services."failure-notification@" = {
      description = "Send a notification about a failure in %I";
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig =
        let
          gatherJournal = pkgs.writeShellScript "failure-gather-journal" ''
            journalctl -u "$1" -b -n100 > "$RUNTIME_DIRECTORY/log"

            # Access to file is protected by RuntimeDirectoryMode
            chmod 0444 -- "$RUNTIME_DIRECTORY/log"
          '';

          sendNotification = pkgs.writeShellScript "failure-send-notification" ''
            set -euo pipefail

            {
              echo "Subject: [groves] Service failure: $1"
              echo ""
              echo "The service unit $1 has failed on host groves. It is currently $(date -u)."
              echo ""
              echo "Up to 100 lines of journal context follow:"
              echo ""
              cat "$RUNTIME_DIRECTORY/log"
            } | ${lib.escapeShellArg "${pkgs.msmtp}/bin/msmtp"} \
                --host=mail.unspecified.systems \
                --port=465 \
                --tls=on \
                --tls-starttls=off \
                --tls-trust-file=/etc/ssl/certs/ca-certificates.crt \
                --auth=plain \
                --user="sys.groves@unspecified.systems" \
                --from="sys.groves@unspecified.systems" \
                --passwordeval="cat -- \"\$CREDENTIALS_DIRECTORY/failure-email-password\"" \
                "sys_groves@randomcat.org"
          '';
        in
        {
          Type = "oneshot";

          LoadCredentialEncrypted = [
            "failure-email-password:${./secrets/failure-email-password}"
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
