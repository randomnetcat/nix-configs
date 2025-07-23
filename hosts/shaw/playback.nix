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

    hardware = {
      intel-gpu-tools.enable = true;

      graphics = {
        enable = true;

        extraPackages = [
          pkgs.intel-media-driver
          pkgs.intel-compute-runtime-legacy1
          pkgs.intel-ocl
        ];
      };
    };

    # Configure the use of intel-media-driver.

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    systemd.services.jellyfin.environment = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
