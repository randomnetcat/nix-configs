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

    wikiteam3-nix = {
      url = "github:randomnetcat/nix-wrappers?dir=wikiteam3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      type = "github";
      owner = "serokell";
      repo = "deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    diplomacy-bot = {
      url = "gitlab:randomnetcat/diplomacy-bot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix = {
      url = "git+https://git.lix.systems/lix-project/lix";
      flake = false;
    };

    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module";
      inputs.lix.follows = "lix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgsSmall, home-manager, nur, deploy-rs, flake-utils, lix-module, ... }@inputs:
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

      lixCache = {
        config = {
          nix.settings.extra-substituters = [
            "https://cache.lix.systems"
          ];

          nix.settings.trusted-public-keys = [
            "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
          ];
        };
      };

      commonModules = [
        systemConfigurationRevision

        home-manager.nixosModules.home-manager
        homeManagerNurOverlay

        lix-module.nixosModules.default
        lixCache
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

      nixosConfigurations = {
        groves = defineSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/groves ];
        };

        reese = defineSystem {
          pkgsFlake = nixpkgsSmall;
          system = "aarch64-linux";
          modules = [ ./hosts/reese ];
        };

        bear = defineSystem {
          pkgsFlake = nixpkgsSmall;
          system = "aarch64-linux";
          modules = [ ./hosts/bear ];
        };

        shaw = defineSystem {
          pkgsFlake = nixpkgsSmall;
          system = "x86_64-linux";
          modules = [ ./hosts/shaw ];
        };
      };

      remoteConfigs = {
        reese = {
          hostname = "reese";
          sshUser = "root";
          remoteBuild = true;
        };

        bear = {
          hostname = "bear";
          sshUser = "root";
          remoteBuild = true;
        };

        shaw = {
          hostname = "shaw";
          sshUser = "root";
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
