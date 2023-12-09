{ pkgs, lib, ... }:

{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    boot.loader.systemd-boot.editor = false;
    boot.loader.efi.efiSysMountPoint = "/boot";

    boot.initd.systemd = {
      enable = true;
      emergencyAccess = "$y$j9T$VFWFsSdjfFxZ0ulNmde6z/$BGUb8vViS0moC3YLGdCF9Y4lrB697tO9AM3aFFoKpB3";

      networks."50-enp4s0" = {
        matchConfig.Name = "enp4s0";

        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };

        # linkConfig.RequiredForOnline = "routable";
      };

      networks."50-enp3s0" = {
        matchConfig.Name = "enp3s0";

        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };

        # linkConfig.RequiredForOnline = "routable";
      };
    };

    boot.initrd.network = {
      ssh = {
        enable = true;
        port = 33;

        hostKeys = [
          ./ssh/initrd_ssh_rsa_key
          ./ssh/initrd_ssh_ed25519_key
        ];

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHagOaeTR+/7FL9sErciMw30cmV/VW8HU7J3ZFU5nj9 janet@randomcat.org"
        ];
      };
    };
  };
}
