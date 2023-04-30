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

    deploy-rs = {
      # Temporarily use workaround from https://github.com/serokell/deploy-rs/pull/203
      type = "github";
      owner = "serokell";
      repo = "deploy-rs";
      ref = "rvem/%23202-add-workaround-for-derivations-store-paths-interpolation";
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

  outputs = { self, nixpkgs, nixpkgsSmall, home-manager, nur, agenix, deploy-rs, flake-utils, ... }@inputs:
    let
      lib = nixpkgs.lib;

      systemConfigurationRevision = {
        config = {
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
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

        home-manager.nixosModules.home-manager
        homeManagerNurOverlay

        agenix.nixosModules.default
      ];

      systemModules = path: commonModules ++ [ path ];

      defineSystem = { pkgsFlake ? nixpkgs, system ? null, modules }@sysArgs: pkgsFlake.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ modules ++ [
          # Provide only a single nixpkgs input to the configuration, regardless of which nixpkgs input is actually being used.
          ({
            _module.args.inputs =
              let
                inputsNoPkgs = (pkgsFlake.lib.filterAttrs (k: v: !(pkgsFlake.lib.strings.hasPrefix "nixpkgs" k)) inputs);
              in
              (inputsNoPkgs // { nixpkgs = pkgsFlake; })
            ;

            _module.args.defineNestedSystem = { modules }@nestedArgs: defineSystem (sysArgs // nestedArgs);
          })
        ];
      };

      defineSystemX64 = args: defineSystem (args // { system = "x86_64-linux"; });
      defineSystemAarch64 = args: defineSystem (args // { system = "aarch64-linux"; });

      defineSimpleSystemX64 = module: defineSystemX64 { modules = [ module ]; };
      defineSimpleSystemAarch64 = module: defineSystemAarch64 { modules = [ module ]; };

      nixosConfigurations = {
        groves = defineSimpleSystemX64 ./hosts/groves/default.nix;
        reese = defineSimpleSystemAarch64 ./hosts/reese/default.nix;
        leon = defineSimpleSystemX64 ./hosts/leon/default.nix;
        bear = defineSimpleSystemAarch64 ./hosts/bear/default.nix;
      };

      remoteConfigs = {
        reese = {
          hostname = "reese";
          sshUser = "root";
          remoteBuild = true;
        };

        leon = {
          hostname = "leon";
          sshUser = "root";
          remoteBuild = false;
        };

        bear = {
          hostname = "bear";
          sshUser = "root";
          remoteBuild = false;
        };
      };

      deployNodes = lib.mapAttrs (name: value: {
        profiles.system = let config = self.nixosConfigurations."${name}"; in {
          user = "root";
          path = deploy-rs.lib."${config.pkgs.system}".activate.nixos config;
        };

        profilesOrder = [ "system" ];
      } // value) remoteConfigs;
    in
    {
      inherit nixosConfigurations;

      deploy.nodes = deployNodes;
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
