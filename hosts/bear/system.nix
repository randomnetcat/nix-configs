{ modulesPath, pkgs, lib, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.localSystem.system = "aarch64-linux";

  boot.loader = {
    efi.efiSysMountPoint = "/boot";

    grub.enable = false;

    systemd-boot = {
      enable = true;
      editor = false;
    };
  };

  boot.initrd.kernelModules = [ "nvme" ];
}
