{ config, lib, pkgs, ... }:

let
  zedEmail = "sys.shaw@unspecified.systems";
  zedPasswordPath = "/run/keys/zed-email-password";
in
{
  config = {
    services.zfs.autoScrub.enable = true;
    services.zfs.trim.enable = true;

    services.zfs.zed = {
      enableMail = false;

      settings = {
        ZED_EMAIL_ADDR = [ "sys_shaw@randomcat.org" ];
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
              --user=${lib.escapeShellArg zedEmail} \
              --from=${lib.escapeShellArg zedEmail} \
              --passwordeval=${lib.escapeShellArg "cat -- ${lib.escapeShellArg zedPasswordPath}"} \
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
        cp --no-preserve=mode,ownership -- "$CREDENTIALS_DIRECTORY/zed-email-password" ${lib.escapeShellArg zedPasswordPath}
        chmod 750 -- ${lib.escapeShellArg zedPasswordPath}
      '';
    };
  };
}
