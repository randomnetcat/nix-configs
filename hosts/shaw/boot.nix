{ pkgs, lib, ... }:

{
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = false;

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.generationsDir.copyKernels = true;

    boot.loader.systemd-boot.editor = false;
    boot.loader.efi.efiSysMountPoint = "/boot";

    boot.initrd.network.ssh = {
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
}
