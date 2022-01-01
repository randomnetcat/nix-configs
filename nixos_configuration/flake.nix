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

            nix.nixPath = [ "nixpkgs=/run/active-nixpkgs-source" ];

            systemd.services.create-nixpkgs-source-link = {
              wantedBy = [ "multi-user.target" ];

              unitConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                RequiresMountsFor = "/run";
              };

              script = ''
                ln -sfT -- ${nixpkgs.lib.escapeShellArg "${nixpkgs}"} /run/active-nixpkgs-source
              '';
            };
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
        randomcat-laptop-nixos = nixpkgs.lib.nixosSystem {
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
