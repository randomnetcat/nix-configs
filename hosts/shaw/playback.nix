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
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };

    hardware.intel-gpu-tools.enable = true;

    hardware.graphics = {
      enable = true;

      extraPackages = [
        pkgs.intel-media-driver
        pkgs.intel-vaapi-driver
        pkgs.intel-compute-runtime-legacy1
        pkgs.vaapiVdpau
        pkgs.libvdpau-va-gl
        pkgs.intel-ocl
        pkgs.vpl-gpu-rt
      ];
    };
  };
}
