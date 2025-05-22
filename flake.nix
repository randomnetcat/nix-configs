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

    colmena = {
      url = "github:zhaofengli/colmena";
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

    qenyaNixfiles = {
      url = "git+https://git.qenya.tel/qenya/nixfiles.git";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-small.follows = "nixpkgsSmall";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    assessor-thesis = {
      url = "github:randomnetcat/assessor-thesis/nix";
      # Don't set nixpkgs to follow because we aren't linking any binaries from this.
    };
  };

  outputs = { self, nixpkgs, nixpkgsSmall, home-manager, nur, colmena, flake-utils, lix-module, lanzaboote, ... }@inputs:
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
            nurPkgs = pkgs.extend nur.overlays.default;
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

        lanzaboote.nixosModules.lanzaboote
      ];

      systemModules = path: commonModules ++ [ path ];

      mkFullSystemModules = { name ? null, pkgsFlake ? nixpkgs, system, modules }@sysArgs: (commonModules ++ modules ++ [
        # Provide only a single nixpkgs input to the configuration, regardless of which nixpkgs input is actually being used.
        ({
          _module.args.inputs =
            let
              inputsNoPkgs = (pkgsFlake.lib.filterAttrs (k: v: !(pkgsFlake.lib.strings.hasPrefix "nixpkgs" k)) inputs);
            in
            (inputsNoPkgs // { nixpkgs = pkgsFlake; })
          ;

          _module.args.defineNestedSystem = { modules }@nestedArgs: defineSystem (sysArgs // { name = null; } // nestedArgs);

          _module.args.name = lib.mkIf (name != null) name;
        })
      ]);

      defineSystem = { name ? null, pkgsFlake ? nixpkgs, system ? null, modules }@sysArgs: pkgsFlake.lib.nixosSystem {
        inherit system;
        modules = mkFullSystemModules sysArgs;

        specialArgs = {
          nodes = nixosConfigurations;
        };
      };

      systemConfigs = {
        carter = {
          system = "x86_64-linux";
          modules = [ ./hosts/carter ];
        };

        reese = {
          pkgsFlake = nixpkgsSmall;
          system = "aarch64-linux";
          modules = [ ./hosts/reese ];
        };

        bear = {
          pkgsFlake = nixpkgsSmall;
          system = "aarch64-linux";
          modules = [ ./hosts/bear ];
        };

        shaw = {
          pkgsFlake = nixpkgsSmall;
          system = "x86_64-linux";
          modules = [ ./hosts/shaw ];
        };

        leon = {
          pkgsFlake = nixpkgsSmall;
          system = "x86_64-linux";
          modules = [ ./hosts/leon ];
        };
      };

      nixosConfigurations = lib.mapAttrs (n: v: defineSystem (v // { name = v.name or n; })) systemConfigs;

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };

          nodeNixpkgs = lib.mapAttrs
            (name: sysArgs: import (sysArgs.pkgsFlake or nixpkgs) {
              system = sysArgs.system;
            })
            systemConfigs;
        };
      } // (lib.mapAttrs
        (name: sysArgs: { config, lib, pkgs, ... }: {
          imports = mkFullSystemModules sysArgs;

          config = {
            nixpkgs.localSystem.system = sysArgs.system;

            deployment = {
              buildOnTarget = true;
              targetHost = config.randomcat.network.hosts.${name}.tailscaleIP4;
              targetUser = null;
            };
          };
        })
        systemConfigs);
    in
    (flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages."${system}".nixpkgs-fmt;
    })) // {
      inherit nixosConfigurations colmena;
    };
}
