{
  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    agorabot-prod = {
      url = "github:randomnetcat/AgoraBot/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agorabot-secret-hitler = {
      url = "github:randomnetcat/AgoraBot/secret-hitler";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, agorabot-prod, agorabot-secret-hitler, agenix }:
    let
      systemConfigurationRevision = {
        config = {
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
        };
      };

      pinnedNixpkgsFlake = {
        config = {
          nix.registry.nixpkgs.flake = nixpkgs;

          environment.etc."active-nixpkgs-source".source = "${nixpkgs}";
          nix.nixPath = [ "nixpkgs=/etc/active-nixpkgs-source" ];
        };
      };

      commonModules = [
        systemConfigurationRevision
        pinnedNixpkgsFlake
        ./modules/wants/resolved
        ./modules/wants/unstable-nix
      ];

      commonVmModules = commonModules ++ [
        ./modules/impl/vm-global.nix
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

        coe-env = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonVmModules ++ [
            ./hosts/coe-env/default.nix
            homeManager
            homeManagerNurOverlay
          ];
        };
      };

      nixopsConfigurations.default = {
        network.storage.legacy = {};
        inherit nixpkgs;

        oracle-server = { pkgs, config, ... }: {
          imports = [
            ./hosts/reese
            agenix.nixosModule
          ];

          config = {
            randomcat.services.agorabot-server.instances = {
              agora-prod.package = (pkgs.extend agorabot-prod.overlays.default).randomcat.agorabot;
              secret-hitler.package = (pkgs.extend agorabot-secret-hitler.overlays.default).randomcat.agorabot;
            };
          };
        };
      };
    };
}
