{ pkgs, lib, ... }:

{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    boot.loader.systemd-boot.editor = false;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # boot.initrd.systemd = {
    #   enable = true;
    #   emergencyAccess = "$y$j9T$VFWFsSdjfFxZ0ulNmde6z/$BGUb8vViS0moC3YLGdCF9Y4lrB697tO9AM3aFFoKpB3";
    # };
  };
}
