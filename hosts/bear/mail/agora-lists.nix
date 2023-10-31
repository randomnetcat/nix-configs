{ config, pkgs, lib, ... }:

let
  hostIP4 = "10.232.148.11";
  localIP4 = "10.231.149.11";
  hostIP6 = "fd50:fe53:b222:1::1";
  localIP6 = "fd50:fe53:b222:2::1";

  mailmanHost = "agora.nomic.space";
  mailmanRoot = "/lists";

  mailmanLmtpPort = 8024;
  mailmanWebPort = 8001;
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
          };

          webHosts = [
            mailmanHost
          ];

          hyperkitty.enable = true;

          settings.webservice = {
            hostname = mailmanHost;
            port = toString mailmanWebPort;
            use_https = "no";
          };
        };

        systemd.services.mailman-settings = {
          script = lib.mkAfter ''
            ${pkgs.replace-secret}/bin/replace-secret '#REPLACE_SMTP_PASS#' "$CREDENTIALS_DIRECTORY/mailman-smtp-pass" /etc/mailman.cfg
          '';

          serviceConfig = {
            LoadCredential = [ "mailman-smtp-pass" ];
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
      ];
    };

    systemd.services."container@agora-lists" = {
      serviceConfig = {
        LoadCredentialEncrypted = [
          "agora-mailman-smtp-pass:${../secrets/agora-mailman-smtp-pass}"
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
