{ config, lib, pkgs, ... }:

{
  config = {
    services.zfs.autoScrub.enable = true;
    services.zfs.trim.enable = true;

    services.zfs.zed = {
      enableMail = false;

      settings = {
        ZED_EMAIL_ADDR = [ "sys_groves@randomcat.org" ];
        ZED_EMAIL_OPTS = "'@ADDRESS@' '@SUBJECT@'";

        ZED_NOTIFY_INTERVAL_SECS = 3600;
        ZED_NOTIFY_VERBOSE = true;

        ZED_USE_ENCLOSURE_LEDS = true;
        ZED_SCRUB_AFTER_RESILVER = true;

        ZED_EMAIL_PROG = "${pkgs.writeShellScript "zed-sendmail" ''
          {
              echo "Subject: $2"
              echo ""
              cat
          } | ${lib.escapeShellArg "${pkgs.msmtp}/bin/msmtp"} \
              --host=mail.unspecified.systems \
              --port=465 \
              --tls=on \
              --tls-starttls=off \
              --tls-trust-file=/etc/ssl/certs/ca-certificates.crt \
              --auth=plain \
              --user="sys.groves@unspecified.systems" \
              --from="sys.groves@unspecified.systems" \
              --passwordeval='cat /run/keys/zed-email-password' \
              "$1"
        ''}";
      };
    };

    systemd.services."zfs-zed-init-creds" = {
      requiredBy = [ "zfs-zed.service" ];
      before = [ "zfs-zed.service" ];

      unitConfig = {
        RequiresMountsFor = [
          "/run/keys"
        ];
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        LoadCredentialEncrypted = [
          "zed-email-password:${./secrets/zed-email-password}"
        ];
      };

      script = ''
        umask 077
        cp --no-preserve=mode,ownership -- "$CREDENTIALS_DIRECTORY/zed-email-password" /run/keys/zed-email-password
        chmod 750 /run/keys/zed-email-password
      '';
    };
  };
}
