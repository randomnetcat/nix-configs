{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/nur";
    };

    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    nixpkgsSmall = {
      url = "github:nixos/nixpkgs/nixos-unstable-small";
    };

    agorabot-prod = {
      url = "github:randomnetcat/AgoraBot/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wikiteam3-nix = {
      url = "github:randomnetcat/nix-wrappers?dir=wikiteam3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    diplomacy-bot = {
      url = "gitlab:randomnetcat/diplomacy-bot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    patched-sanoid = {
      url = "github:randomnetcat/sanoid";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgsSmall, home-manager, nur, agenix, flake-utils, ... }@inputs:
    let
      systemConfigurationRevision = {
        config = {
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
        };
      };

      inputsArg = {
        config = {
          _module.args.inputs = inputs;
        };
      };

      homeManagerNurOverlay = { pkgs, ... }: {
        config = {
          home-manager.extraSpecialArgs = {
            nurPkgs = pkgs.extend nur.overlay;
          };
        };
      };

      commonModules = [
        systemConfigurationRevision
        inputsArg

        home-manager.nixosModules.home-manager
        homeManagerNurOverlay

        agenix.nixosModules.default
      ];

      systemModules = path: commonModules ++ [ path ];

      defineSystem = { pkgs ? nixpkgs, system ? null, modules }: pkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ modules;
      };

      defineSystemX64 = args: defineSystem (args // { system = "x86_64-linux"; });
      defineSystemAarch64 = args: defineSystem (args // { system = "aarch64-linux"; });

      defineSimpleSystemX64 = module: defineSystemX64 { modules = [ module ]; };
      defineSimpleSystemAarch64 = module: defineSystemAarch64 { modules = [ module ]; };

      nixosConfigurations = {
        groves = defineSimpleSystemX64 ./hosts/groves/default.nix;
        reese = defineSimpleSystemAarch64 ./hosts/reese/default.nix;

        coe-env = defineSimpleSystemX64 ./hosts/coe-env/default.nix;
        csc-216-env = defineSimpleSystemX64 ./hosts/csc-216-env/default.nix;
        csc-326-env = defineSimpleSystemX64 ./hosts/csc-326-env/default.nix;
        csc-510-env = defineSimpleSystemX64 ./hosts/csc-510-env/default.nix;
      };
    in
    {
      inherit nixosConfigurations;

      colmena = {
        meta = {
          nixpkgs = import nixpkgsSmall {
            system = "x86_64-linux";
          };
        };

        reese = {
          imports = systemModules ./hosts/reese;

          deployment.buildOnTarget = true;
          system.nixos.revision = nixpkgsSmall.rev;
        };

        leon = {
          imports = systemModules ./hosts/leon;

          system.nixos.revision = nixpkgsSmall.rev;
        };
      };
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";

        # Adapted from https://discourse.nixos.org/t/get-qemu-guest-integration-when-running-nixos-rebuild-build-vm/22621/2
        mkRunEnv = hostName: pkgs.writeShellApplication {
          name = "run-${hostName}";
          runtimeInputs = [ pkgs.virt-viewer ];
          text = ''
            ${nixosConfigurations."${hostName}".config.system.build.vm}/bin/run-nixos-vm & PID_QEMU="$!"
            sleep 1
            remote-viewer spice://127.0.0.1:5930
            kill $PID_QEMU
          '';
        };
      in
      {
        packages.run-coe-env = mkRunEnv "coe-env";
        packages.run-csc-510-env = mkRunEnv "csc-510-env";
      }
      ));
}
