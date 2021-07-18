# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.version = 2;
  # boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.generationsDir.copyKernels = true;

  networking.hostName = "randomcat-laptop-nixos"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp60s0.useDHCP = true;
  networking.interfaces.wlo1.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false;
  services.xserver.desktopManager.gnome.enable = true;

  # services.xserver.desktopManager.gnome3.extraGSettingsOverrides = ''
  #   [org.gnome.desktop.peripherals.touchpad]
  #   click-method='default'
  # '';

  # Configure keymap in X11
  # services.xserver.layout = "us";
  services.xserver.xkbOptions = "lv3:ralt_alt";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.randomcat = {
    isNormalUser = true;
    group = "randomcat";
    extraGroups = [ "users" "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
  };

  users.groups.randomcat = {
    members = [ "randomcat" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [
    pkgs.nano
    pkgs.git
    pkgs.bindfs
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  fileSystems."/" = {
    device = "/dev/mapper/vg_rcat-nixos_root";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/vg_rcat-nixos_nix_store";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixos_boot";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/A0A9-C254";
    fsType = "vfat";
  };

  fileSystems."/home" = {
    device = "/dev/mapper/vg_rcat-nixos_home";
    fsType = "ext4";
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/vg_rcat-nixos_persist";
    fsType = "ext4";
  };

  fileSystems."/root/mountpoints/dev_projects" = {
    device = "/dev/mapper/vg_rcat-data_dev_projects";
    fsType = "ext4";
  };

  fileSystems."/home/randomcat/dev/projects" = {
    device = "/root/mountpoints/dev_projects";
    fsType = "fuse.bindfs";
    options = [ "force-user=randomcat" "force-group=randomcat" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  environment.etc."nixos" = {
    source = "/persist/configs/nixos_configuration";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

