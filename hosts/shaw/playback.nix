{ pkgs, lib, ... }:

{
  config = {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    users.users.jellyfin = {
      extraGroups = [
        "archive" # for file permissions
        "render"  # for hardware transcoding
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

    hardware.opengl = {
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
