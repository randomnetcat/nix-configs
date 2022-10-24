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
      # If updating this, must also update pin below
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    agorabot-prod = {
      url = "github:randomnetcat/AgoraBot/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, agenix, ... }@inputs:
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
        finch = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModules ++ [
            ./hosts/finch/default.nix
            homeManager
            homeManagerNurOverlay
            # ./modules/wants/virtualisation
          ];
        };

        groves = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModules ++ [
            ./hosts/groves/default.nix
            homeManager
            homeManagerNurOverlay
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
        inherit nixpkgs;

        oracle-server = { pkgs, config, ... }: {
          imports = commonModules ++ [
            ./hosts/reese
            agenix.nixosModule
          ];
        };
      };
    };
}
