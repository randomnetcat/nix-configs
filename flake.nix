{
  inputs = {
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
  };

  outputs = { self, nixpkgs, nixpkgsSmall, home-manager, nur, agenix, ... }@inputs:
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

      commonModules = [
        systemConfigurationRevision
        inputsArg
      ];

      homeManager = home-manager.nixosModules.home-manager;
      homeManagerNurOverlay = {
        config = {
          home-manager.extraSpecialArgs = {
            nurPkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [ nur.overlay ];
              config = { allowUnfree = true; };
            };
          };
        };
      };
    in
    {
      nixosConfigurations = {
        groves = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModules ++ [
            ./hosts/groves/default.nix
            homeManager
            homeManagerNurOverlay
          ];
        };

        reese = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";

          modules = commonModules ++ [
            ./hosts/reese/default.nix
            agenix.nixosModule
          ];
        };

        coe-env = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModules ++ [
            ./hosts/coe-env/default.nix
            homeManager
            homeManagerNurOverlay
          ];
        };

        csc-216-env = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModules ++ [
            ./hosts/csc-216-env/default.nix
            homeManager
            homeManagerNurOverlay
          ];
        };

        csc-326-env = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModules ++ [
            ./hosts/csc-326-env/default.nix
            homeManager
            homeManagerNurOverlay
          ];
        };
      };

      nixopsConfigurations.default = {
        network.storage.legacy = {};
        nixpkgs = nixpkgsSmall;

        oracle-server = { pkgs, config, ... }: {
          imports = commonModules ++ [
            ./hosts/reese
            agenix.nixosModule

            {
              deployment.targetHost = "reese";
            }
          ];
        };
      };
    };
}
