{ config, lib, pkgs, ... }:

{
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
      openFirewall = true;
    };

    users.users.jellyfin = {
      extraGroups = [
        "archive" # for file permissions
        "render" # for hardware transcoding
      ];

      packages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
      ];
    };

    # From https://nixos.wiki/wiki/Jellyfin

    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };

    hardware.graphics = {
      enable = true;

      extraPackages = [
        pkgs.intel-media-driver
        pkgs.vaapiIntel
        pkgs.vaapiVdpau
        pkgs.libvdpau-va-gl
        pkgs.intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };
  };
}
