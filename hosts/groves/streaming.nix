{ config, lib, pkgs, ... }:

let
  jellyfinUpstream = "127.0.0.1";
in
{
  imports = [
    ./proxy.nix
  ];

  config = {
    randomcat.services.fs-keys.cifs-shaw-archive-creds = {
      requiredBy = [ "srv-archive.mount" ];
      before = [ "srv-archive.mount" ];

      keys.cifs-shaw-archive = {
        source.encrypted.path = ./secrets/cifs-shaw-archive;

        user = "root";
        group = "root";
        mode = "0400";
      };
    };

    randomcat.services.zfs.datasets."rpool_fxooop/groves/local/fscache" = {
      zfsOptions = {
        # Per https://github.com/openzfs/zfs/issues/10473#issuecomment-646211412
        "recordsize" = "4k";

        # These features are required per https://docs.kernel.org/filesystems/caching/cachefiles.html
        "xattr" = "sa";
        "atime" = "on";
      };

      mountpoint = "/mnt/fscache";
    };

    fileSystems."/srv/archive" = {
      fsType = "cifs";
      device = "//shaw.birdsong.network/archive";

      options = [
        "credentials=/run/keys/cifs-shaw-archive"
        "ro"

        "nosuid"
        "nodev"
        "noexec"

        "nofail"
        "x-systemd.device-bound=tailscaled.service"
        "x-systemd.after=tailscaled.service"
        "x-systemd.wants=tailscale-autoconnect.service"
        "x-systemd.after=tailscale-autoconnect.service"

        # Based on https://nixos.wiki/wiki/Samba
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=120"
        "x-systemd.device-timeout=30s"
        "x-systemd.mount-timeout=30s"

        # TODO: Convince these to work? I'm not sure why they aren't.
        # "forceuid=${toString config.users.users.archive.uid}"
        # "forcegid=${toString config.users.groups.archive.gid}"

        # Caching; depends on cachefilesd below.
        "fsc"
      ];
    };

    services.cachefilesd = {
      enable = true;
      cacheDir = "/mnt/fscache/storage";
    };

    services.jellyfin = {
      enable = true;
      openFirewall = false;
    };

    users.users.jellyfin = {
      extraGroups = [
        "archive" # for file permissions
        "render" # for hardware transcoding
        "video" # for hardware transcoding
      ];

      packages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
      ];
    };

    # From https://nixos.wiki/wiki/Jellyfin

    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };

    hardware.graphics = {
      enable = true;

      extraPackages = [
        pkgs.intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        pkgs.intel-media-driver
        pkgs.intel-vaapi-driver
        pkgs.libva-vdpau-driver
        pkgs.libvdpau-va-gl
        pkgs.vpl-gpu-rt
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/manual-certs 0750 root ${config.users.groups.nginx.name} -"
      "Z /var/lib/manual-certs/* 0640 root ${config.users.groups.nginx.name} -"
    ];

    services.nginx = {
      virtualHosts."tv.randomcat.gay" = {
        forceSSL = true;
        sslCertificate = "/var/lib/manual-certs/tv.randomcat.gay.crt";
        sslCertificateKey = "/var/lib/manual-certs/tv.randomcat.gay.key";

        locations."/" = {
          proxyPass = "http://${jellyfinUpstream}:8096";
          recommendedProxySettings = true;

          extraConfig = ''
            proxy_buffering off;
          '';
        };

        locations."/socket" = {
          proxyPass = "http://${jellyfinUpstream}:8096";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };

        extraConfig = ''
          client_max_body_size 20M;

          add_header X-Content-Type-Options "nosniff";
          add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;
          add_header Content-Security-Policy "default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";
        '';
      };
    };

    assertions = [
      {
        assertion = config.services.nginx.enable;
        message = "nginx must be enabled for reverse proxying";
      }
    ];
  };
}
