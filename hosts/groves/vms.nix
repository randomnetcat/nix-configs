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

            ## Force enabling of qxl (mkVmOverride in the module has priority 10, taking precedence over even mkForce, so we have to be even lower than that).
            services.xserver.videoDrivers = lib.mkOverride 0 [ "modesetting" "qxl" ];

            ## Force allowing X to determine its own resolutions.
            services.xserver.resolutions = lib.mkOverride 0 [];

            ## Enable SPICE
            virtualisation.qemu.options = [
              "-vga qxl -device virtio-serial-pci -spice port=5930,disable-ticketing=on -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent"
            ];
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
                  binName = "run-${name}-vm";

                  vm = buildVm {
                    inherit name;
                    modules = [ path ];
                    targetPath = "${config.home.homeDirectory}/dev/vms/${name}";
                  };

                  runPkg = pkgs.writeShellApplication {
                    name = binName;

                    runtimeInputs = [ pkgs.virt-viewer ];

                    # Adapted from https://discourse.nixos.org/t/get-qemu-guest-integration-when-running-nixos-rebuild-build-vm/22621/2
                    text = ''
                      ${vm.config.system.build.vm}/bin/run-${vm.config.networking.hostName}-vm & PID_QEMU="$!"
                      sleep 1
                      remote-viewer spice://127.0.0.1:5930
                      kill "$PID_QEMU"
                    '';
                  };
                in
                "${runPkg}/bin/${binName}";
            };
          }) vmModules;
        })
      ];
    };
}
