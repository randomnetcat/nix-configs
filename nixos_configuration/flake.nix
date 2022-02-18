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
  };

  outputs = { self, nixpkgs, home-manager, nur }: {
    nixosConfigurations =
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
        finch = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModules ++ [
            ./hosts/finch/default.nix
            homeManager
            homeManagerNurOverlay
            ./modules/wants/virtualisation
          ];
      };
    };
  };
}
