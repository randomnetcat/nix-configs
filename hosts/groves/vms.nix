{ defineNestedSystem, ... }:

{
  config =
    let
      vmModules = {
        coe-env = ../coe-env;
        csc-510-env = ../csc-510-env;
      };

      vmExtraModules = name: [
        ({ pkgs, lib, ... }: {
          networking.hostName = lib.mkDefault name;
          virtualisation.qemu.package = pkgs.qemu_kvm;
        })
      ];

      buildVm = { name, path }: defineNestedSystem { modules = [ path ] ++ (vmExtraModules name); };
    in
    {
      home-manager.users.randomcat.imports = [
        ({ pkgs, lib, ... }: {
          home.file = lib.mapAttrs' (name: path: {
            name = "dev/vms/${name}/run-vm";

            value = {
              source =
                let
                  binName = "run-${name}-vm";

                  vm = buildVm { inherit name path; };

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
