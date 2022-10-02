{ modulesPath, pkgs, lib, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.localSystem.system = "aarch64-linux";

  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.initrd.kernelModules = [ "nvme" ];
}
