{ config, pkgs, lib, ... }:

{
  imports = [
    ../../presets/ncsu-vm-env.nix
    ./locale.nix
    ./development.nix
  ];

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.11"; # Did you read the comment?

    virtualisation.writableStore = true;
    virtualisation.writableStoreUseTmpfs = true;

    virtualisation.sharedDirectories.hostshare = {
      source = "/home/randomcat/dev/csc-510-env/shared-dir";
      target = "/host-shared";
    };

    home-manager.useUserPackages = true;

    environment.systemPackages = [
      pkgs.vim
      pkgs.firefox
      pkgs.vscode
      pkgs.steam-run
      pkgs.nodejs
      pkgs.nodePackages.npm
    ];

    virtualisation.docker.enable = true;
    users.users.randomcat.extraGroups = [ "docker" ];

    # Guest agents
    virtualisation.qemu.guestAgent.enable = true;
    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true;
    services.spice-webdavd.enable = true;

    # Force enabling of qxl (mkVmOverride in the module has priority 10, taking precedence over even mkForce, so we have to be even lower than that).
    services.xserver.videoDrivers = lib.mkOverride 0 [ "modesetting" "qxl" ];

    # Force allowing X to determine its own resolutions.
    services.xserver.resolutions = lib.mkOverride 0 [];

    # Enable SPICE
    virtualisation.qemu.options = [
      "-vga qxl -device virtio-serial-pci -spice port=5930,disable-ticketing=on -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent"
    ];
  };
}
