{ config, pkgs, lib, ... }:

let
  cfg = config.randomcat.system.efi;
in
{
  options = {
    randomcat.system.efi = {
      enable = lib.mkEnableOption "randomcat EFI management";

      espDevice = lib.mkOption {
        type = lib.types.str;
        description = "Device for the efi system partition";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    fileSystems."/efi" = {
      device = cfg.espDevice;
      fsType = "vfat";
    };

    boot.loader.efi.efiSysMountPoint = "/efi";

    boot.loader.generationsDir.copyKernels = true;
  };
}
