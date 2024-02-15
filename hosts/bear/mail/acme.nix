{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.mail;
  primary = cfg.primaryDomain;
  allDomains = [ primary ] ++ cfg.extraDomains;
in
{
  config = {
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "jason.e.cobb@gmail.com";

    users.users.nginx.extraGroups = [ "acme" ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.nginx = {
      virtualHosts = lib.mkMerge [
        {
          "acmechallenge.${primary}" = {
            serverAliases = [ "*.${primary}" ];

            locations."/.well-known/acme-challenge" = {
              root = "/var/lib/acme/.challenges";
            };

            locations."/" = {
              return = "301 https://$host$request_uri";
            };
          };
        }

        (lib.listToAttrs (map (domain: {
          name = "mta-sts.${domain}";

          value = {
            addSSL = true;
            acmeRoot = config.security.acme.certs."${primary}".webroot;
            useACMEHost = primary;

            locations."=/.well-known/mta-sts.txt".alias = pkgs.writeText "mta-sts.txt" ''
              version: STSv1
              mode: enforce
              max_age: 604800
              mx: mail.${primary}
            '';
          };
        }) allDomains))
      ];
    };

    security.acme.certs."${primary}" = {
      webroot = "/var/lib/acme/.challenges";
      email = "jason.e.cobb@gmail.com";

      # Ensure that the certificate's key does not change. This is required because the public key
      # is hashed for the TLSA DNS record.
      extraLegoRenewFlags = [ "--reuse-key" ];

      extraDomainNames = [
        "mail.${primary}"
        "mta-sts.${primary}"
        "www.${primary}"
      ] ++ (lib.concatMap (d: [
        "mta-sts.${d}"
      ]) cfg.extraDomains);
    };

    assertions = [
      {
        assertion = config.systemd.services.acme-fixperms != {};
        message = "acme-mail service depends on acme-fixperms";
      }
    ];

    systemd.services.acme-mail = {
      requires = [ "acme-fixperms.service" ];
      wants = [ "network-online.target" ];
      after = [ "network.target" "network-online.target" "acme-fixperms.service" ];

      wantedBy = [ "maddy.service" ];
      before = [ "maddy.service" ]; 

      serviceConfig = {
        Type = "oneshot";
        User = "acme";
        Group = "acme";
        WorkingDirectory = "/var/empty";
        UMask = "0022";
        ProtectSystem = "strict";
        PrivateTmp = true;
        CapabilityBoundingSet = [ "" ];
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RemoveIPC = true;

        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];

        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";

        SystemCallFilter = [
          "@system-service @resources"
          "~@privileged"
          "@chown"
        ];

        ReadWritePaths = [
          "/var/lib/acme"
          "/var/lib/acme/.challenges"
        ];

        RestartSec = 15 * 60;

        LoadCredentialEncrypted = [
          "maddy-tls-key:${../secrets/maddy-tls-key}"
        ];
      };

      path = [
        pkgs.lego
        pkgs.openssl
      ];

      script =
        let
          domain = "mail.unspecified.systems";

          commonOpts = [
            "--accept-tos"
            "--path" legoDir
            "--email" config.security.acme.defaults.email
            "--http"
            "--http.webroot" "/var/lib/acme/.challenges"
          ];

          legoDir = "/var/lib/acme/.lego-mail/${domain}";
          outDir = "/var/lib/acme/mail";
        in
        ''
          set -euo pipefail
          cd -- "$(mktemp -d)"

          printf "%s" ${lib.escapeShellArg ''
            [SAN]
            subjectAltName=DNS:${domain}
          ''} > config

          openssl req \
            -new \
            -sha256 \
            -key "$CREDENTIALS_DIRECTORY/maddy-tls-key" \
            -subj ${lib.escapeShellArg "/CN=${domain}"} \
            -reqexts SAN \
            -config config \
            > request.pem

          DOMAIN=${lib.escapeShellArg domain}
          OUT_DIR=${lib.escapeShellArg outDir}
          LEGO_DIR=${lib.escapeShellArg legoDir}

          mkdir -p -m 0700 -- "$LEGO_DIR"

          RENEWED=0

          if [ -e "$LEGO_DIR/certificates/$DOMAIN.crt" ]; then
            echo "Attempting to renew..."

            if lego ${lib.escapeShellArgs commonOpts} --csr request.pem renew; then
              echo "Successfully renewed."
              RENEWED=1
            else
              echo "Failed to renew."
            fi
          else
            echo "No existing certificates -- not attempting to renew."
          fi

          if [ "$RENEWED" != 1 ]; then
            echo "Attempting to acquire new certificate..."
            lego ${lib.escapeShellArgs commonOpts} --csr request.pem run
          fi

          mkdir -p -m 750 -- "$OUT_DIR"
          chmod 750 -- "$OUT_DIR"

          cp -vp -- "$LEGO_DIR/certificates/$DOMAIN.crt" "$OUT_DIR/fullchain.pem"
          cp -vp -- "$LEGO_DIR/certificates/$DOMAIN.issuer.crt" "$OUT_DIR/chain.pem"
          cp -vp -- "$CREDENTIALS_DIRECTORY/maddy-tls-key" "$OUT_DIR/key.pem"
          ln -sf -- fullchain.pem "$OUT_DIR/cert.pem"
          cat -- "$OUT_DIR/key.pem" "$OUT_DIR/fullchain.pem" > "$OUT_DIR/full.pem"

          chmod 640 -- "$OUT_DIR"/*
        '';
    };

    systemd.timers.acme-mail = {
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "5m";
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
