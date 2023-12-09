{ pkgs, config, lib, ... }:

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

    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages.extend (self: super: {
      it87 = super.it87.overrideAttrs (old: rec {
        name = "it87-${version}-${self.kernel.version}";
        version = "unstable-2023-11-11";

        src = pkgs.fetchFromGitHub {
          owner = "frankcrawford";
          repo = "it87";
          rev = "6392311da76b4868efd7b6db8101e10f9e453c75";
          sha256 = lib.fakeSha256;
        };
      });
    });
  };
}
