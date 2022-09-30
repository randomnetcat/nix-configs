{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    ./users/randomcat/user.nix
  ];

  users.mutableUsers = false;

  users.users.randomcat = {
    password = "bad password";
  };

  nixpkgs.config.allowUnfree = true;

  services.xserver = {
    enable = true;

    displayManager = {
      gdm = {
        enable = true;
        wayland = false;
      };

      autoLogin = {
        enable = true;
        user = "randomcat";
      };
    };

    desktopManager = {
      gnome.enable = true;
    };
  };

  virtualisation = {
    qemu.package = pkgs.qemu_kvm;

    memorySize = 8192;
    msize = 262144;
    cores = 6;

    resolution = lib.mkDefault { x = 1920; y = 1080; };
  };
}
