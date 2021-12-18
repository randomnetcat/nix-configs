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

  # Force link-local addresses to be routed by the primary Virtual Network
  # Interface Controller (in Oracle terms).
  #
  # For some reason, Oracle puts important things on link-local addresses (like
  # the default DNS server). This causes problems when, e.g., Docker creates
  # virtual network controllers that route 169.254/16. By default only the
  # single address 169.254.0.0 is routed to the Oracle controller (in addition
  # to it having the default gateway), so the Docker routes are selected
  # because they are more specific than the default route. This command fixes
  # that by forcing 169.254/16 to be routed to the Oracle controller using a
  # lower metric than the Docker routes have (thus taking precedence).
  systemd.services.add-oracle-card-route = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    script = let ipCommand = lib.escapeShellArg "${pkgs.iproute2}/bin/ip"; in ''
      set -euo pipefail

      echo "Routes before:"
      ${ipCommand} route # Log for debugging

      echo "Adding route..."
      ${ipCommand} route replace 169.254.0.0/16 dev enp0s3 scope link metric 1
      echo "Added route."

      echo "Routes after:"
      ${ipCommand} route # Log for debugging
    '';
  };

  fileSystems = {
    "/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "ext4";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-partlabel/ESP";
      fsType = "vfat";
    };
  };

  services.resolved.extraConfig = ''
    DNS=169.254.169.254%enp0s3
  '';
}
