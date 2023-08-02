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

            ## Force allowing X to determine its own resolutions.
            services.xserver.resolutions = lib.mkOverride 0 [];

            ## Configure devices
            virtualisation.qemu.options =
              let
                commonArgs = [
                  "-device virtio-serial-pci"
                  "-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
                  "-chardev spicevmc,id=spicechannel0,name=vdagent"
                ];

                platformArgs = {
                  "x86_64-linux" = [
                    "-device virtio-vga-gl"
                  ];

                  "aarch64-linux" = [
                  ];
                }."${pkgs.stdenv.hostPlatform.system}";
              in
              (commonArgs ++ platformArgs);
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
                  targetPath = "${config.home.homeDirectory}/dev/vms/${name}";

                  vm = buildVm {
                    inherit name targetPath;
                    modules = [ path ];
                  };

                  runPkg = pkgs.writeShellApplication {
                    name = binName;

                    runtimeInputs = [ pkgs.virt-viewer ];

                    # Adapted from https://discourse.nixos.org/t/get-qemu-guest-integration-when-running-nixos-rebuild-build-vm/22621/2
                    text = ''
                      mkdir -p -- ${lib.escapeShellArg "${targetPath}/shared-dir"}

                      SOCK_DIR="$(mktemp -d nix-vm-spice-sock.XXXXXXXXXX --tmpdir="$XDG_RUNTIME_DIR")"
                      SOCK_FILE="$SOCK_DIR/vm.sock"

                      ${vm.config.system.build.vm}/bin/run-${vm.config.networking.hostName}-vm -spice disable-ticketing=on,gl=on,unix=on,addr="$SOCK_FILE" & PID_QEMU="$!"
                      sleep 1
                      remote-viewer "spice+unix://$SOCK_FILE"
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
