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

          serve = {
            enable = true;
            virtualRoot = mailmanRoot;
          };

          webSettings = {
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

            install -m 0770 -o mailman -g mailman -T "$CREDENTIALS_DIRECTORY/django-config" "$mailmanWebDir/settings_randomcat.json"
          '';

          serviceConfig = {
            LoadCredential = [
              "mailman-smtp-pass"
              "django-config"
            ];
          };
        };
      };

      ephemeral = false;
      autoStart = true;

      privateNetwork = true;
      hostAddress = hostIP4;
      hostAddress6 = hostIP6;
      localAddress = localIP4;
      localAddress6 = localIP6;

      extraFlags = [
        "--load-credential=mailman-smtp-pass:agora-mailman-smtp-pass"
        "--load-credential=django-config:agora-django-config"
      ];
    };

    systemd.services."container@agora-lists" = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          # A single line containing the SMTP password to use for mailman
          "agora-mailman-smtp-pass:${../secrets/agora-mailman-smtp-pass}"

          # A JSON file containing config for django:
          # Auth: EMAIL_BACKEND, EMAIL_HOST, EMAIL_PORT, EMAIL_HOST_USER, EMAIL_HOST_PASSWORD, EMAIL_USE_SSL
          # Sender: DEFAULT_FROM_EMAIL, SERVER_EMAIL
          "agora-django-config:${../secrets/agora-django-config}"
        ];
      };
    };

    services.nginx = {
      virtualHosts."${mailmanHost}" = {
        enableACME = true;
        forceSSL = true;

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
