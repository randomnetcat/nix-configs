{ config, pkgs, lib, ... }:

let
  hostIP4 = "10.232.148.11";
  localIP4 = "10.231.149.11";
  hostIP6 = "fd50:fe53:b222:1::1";
  localIP6 = "fd50:fe53:b222:2::1";

  mailmanHost = "agora.nomic.space";
  mailmanRoot = "/lists";

  mailmanLmtpPort = 8024;
in
{
  imports = [
    ./config.nix
  ];

  config = {
    containers.agora-lists = {
      config = { pkgs, lib, ... }: {
        system.stateVersion = "23.11";

        services.resolved.enable = true;
        networking.useHostResolvConf = false;
        networking.firewall.enable = false;

        services.mailman = {
          enable = true;
          siteOwner = "postmaster@unspecified.systems";

          enablePostfix = false;
          settings.mta = {
            incoming = "mailman.mta.null.NullMTA";
            lmtp_host = localIP4;
            lmtp_port = toString mailmanLmtpPort;

            outgoing = "mailman.mta.deliver.deliver";
            smtp_host = "mail.unspecified.systems";
            smtp_port = "465";
            smtp_user = "mailman@agora.nomic.space";
            smtp_pass = "#REPLACE_SMTP_PASS#";
            smtp_secure_mode = "smtps";

            configuration = "${pkgs.emptyFile}";
          };

          settings.ARC = {
            enabled = "yes";
            dmarc = "yes";
            dkim = "yes";
            authserv_id = "agora.nomic.space";
            trusted_authserv_ids = "unspecified.systems";
            privkey = "/var/lib/mailman/arc-key";
            selector = "arc";
            domain = "agora.nomic.space";
          };

          serve = {
            enable = true;
            virtualRoot = mailmanRoot;
          };

          webSettings = {
            # Must be set for Hyperkitty to generate correct permalinks in Archived-At header.
            FORCE_SCRIPT_NAME = "/lists";

            STATIC_URL = "lists/static/";

            # Per https://docs.mailman3.org/en/latest/config-web.html#setting-up-email
            ACCOUNT_AUTHENTICATION_METHOD = "username_email";
            ACCOUNT_EMAIL_REQUIRED = true;
            ACCOUNT_EMAIL_VERIFICATION = "mandatory";
            ACCOUNT_DEFAULT_HTTP_PROTOCOL = "http";
            ACCOUNT_UNIQUE_EMAIL = true;

            POSTORIUS_TEMPLATE_BASE_URL = "http://localhost:80/lists";

            DEFAULT_FROM_EMAIL = "django@agora.nomic.space";
            SERVER_EMAIL = "django@agora.nomic.space";
          };

          webHosts = [
            mailmanHost
          ];

          hyperkitty.enable = true;
        };

        environment.etc."mailman3/settings.py".text = lib.mkAfter ''
          with open('/var/lib/mailman-web/settings_randomcat.json') as f:
              globals().update(json.load(f))
        '';

        systemd.services.mailman-settings = {
          script = lib.mkAfter ''
            ${pkgs.replace-secret}/bin/replace-secret '#REPLACE_SMTP_PASS#' "$CREDENTIALS_DIRECTORY/mailman-smtp-pass" /etc/mailman.cfg

            # First copy the secret to a private directory (mode 0700) then to the target, so it can't be accessed in the interim.
            SECRET_DIR="$(mktemp -d)"

            install -m 0440 -o mailman-web -g mailman -T -- "$CREDENTIALS_DIRECTORY/django-config" "$SECRET_DIR/django-config"
            mv -T -- "$SECRET_DIR/django-config" "$mailmanWebDir/settings_randomcat.json"

            install -m 0440 -o mailman -g mailman -T -- "$CREDENTIALS_DIRECTORY/mailman-arc-key" "$SECRET_DIR/arc-key"
            mv -T -- "$SECRET_DIR/arc-key" "$mailmanDir/arc-key"

            rmdir -- "$SECRET_DIR"
          '';

          serviceConfig = {
            LoadCredential = [
              "mailman-smtp-pass"
              "django-config"
              "mailman-arc-key"
            ];
          };
        };
      };

      ephemeral = false;
      autoStart = true;

      privateUsers = "pick";

      privateNetwork = true;
      hostAddress = hostIP4;
      hostAddress6 = hostIP6;
      localAddress = localIP4;
      localAddress6 = localIP6;

      extraFlags = [
        "--load-credential=mailman-smtp-pass:agora-mailman-smtp-pass"
        "--load-credential=django-config:agora-django-config"
        "--load-credential=mailman-arc-key:agora-mailman-arc-key"
      ];
    };

    systemd.services."container@agora-lists" = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          # A single line containing the SMTP password to use for mailman
          "agora-mailman-smtp-pass:${../secrets/agora-mailman-smtp-pass}"

          # A JSON file containing config for django:
          # Auth: EMAIL_BACKEND, EMAIL_HOST, EMAIL_PORT, EMAIL_HOST_USER, EMAIL_HOST_PASSWORD, EMAIL_USE_SSL
          "agora-django-config:${../secrets/agora-django-config}"

          # Generated with nix run nixpkgs#openssl -- genpkey -out rsakey.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
          # Public key reflected on DNS
          "agora-mailman-arc-key:${../secrets/agora-mailman-arc-key}"
        ];
      };
    };

    services.nginx = {
      virtualHosts."${mailmanHost}" = {
        enableACME = true;
        forceSSL = true;

        root = ../agora-web;

        locations."${lib.removeSuffix "/" mailmanRoot}/" = {
          recommendedProxySettings = true;
          proxyPass = "http://${localIP4}:80";
        };
      };
    };

    randomcat.services.mail.extraDomains = [
      mailmanHost
    ];
  };
}
