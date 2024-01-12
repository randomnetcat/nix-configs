{ defineNestedSystem, pkgs, ... }:

let
  hostPkgs = pkgs;
in
{
  config =
    let
      vmModules = {
        coe-env = ../coe-env;
        csc-510-env = ../csc-510-env;
        coe-env-arch = {
          imports = [ ../coe-env ];
          config = { nixpkgs.localSystem.system = "aarch64-linux"; };
        };
      };

      vmExtraModules = { name, targetPath }: [
        ({ pkgs, lib, modulesPath, ... }: {
          imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

          config = {
            # Set default hostname
            networking.hostName = lib.mkDefault name;

            # Set qemu package
            virtualisation.host.pkgs = hostPkgs;
            virtualisation.qemu.package = lib.mkIf (hostPkgs.stdenv.hostPlatform.system != pkgs.stdenv.hostPlatform.system) hostPkgs.qemu;

            # Add a shared directory
            virtualisation.sharedDirectories.hostshare = {
              source = "${targetPath}/shared-dir";
              target = "/host-shared";
            };

            # Enable full host UI interaction (using custom script below)

            ## Guest agents
            virtualisation.qemu.guestAgent.enable = true;
            services.qemuGuest.enable = true;
            services.spice-vdagentd.enable = true;
            services.spice-webdavd.enable = true;

            ## Force allowing X to determine its own resolutions.
            services.xserver.resolutions = lib.mkOverride 0 [];

            services.xserver.videoDrivers = lib.mkOverride 0 [
              "virtio"
              "modesetting"
            ];

            boot.kernelModules = [
              "virtio"
              "virtio-mmio"
              "virtio-pci"
              "virtio-input"
              "virtio-vdpa"
              "virtio-balloon"
              "virtio-pci-modern-dev"
              "virtio-pci-legacy-dev"
              "virtio-mem"
              "virtio-console"
              "virtio-iommu"
              "virtio-crypto"
              "virtio-snd"
              "virtio-blk"
              "virtio-gpu"
            ];

            ## Configure devices
            virtualisation.qemu.options = {
              "x86_64-linux" = [
                "-vga none"
                "-device virtio-gpu-pci"
              ];

              "aarch64-linux" = [
              ];
            }."${pkgs.stdenv.hostPlatform.system}";
          };
        })
      ];

      buildVm = { name, modules, targetPath }: defineNestedSystem {
        modules = modules ++ (vmExtraModules { inherit name targetPath; });
      };
    in
    {
      home-manager.users.randomcat.imports = [
        ({ pkgs, lib, config, ... }: {
          home.file = lib.mapAttrs' (name: path: {
            name = "dev/vms/${name}/run-vm";

            value = {
              source = 
                let
                  targetPath = "${config.home.homeDirectory}/dev/vms/${name}";
                  vm = buildVm {
                    inherit name targetPath;
                    modules = [ path ];
                  };
                in
                "${vm.config.system.build.vm}/bin/run-${vm.config.networking.hostName}-vm";
            };
          }) vmModules;
        })
      ];
    };
}
