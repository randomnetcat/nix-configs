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
    nixosConfigurations.randomcat-laptop-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (import ./configuration.nix { deviceDir = ./modules/devices/dell-g5-laptop; })
        (import "${home-manager}/nixos")
        { config.system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev; }
        { config.nix.registry.nixpkgs.flake = nixpkgs; }
        {
          config.home-manager.extraSpecialArgs = {
            nurPkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [ nur.overlay ];
              config = { allowUnfree = true; };
            };
          };
        }
        ({ lib, ... }: {
          config = {
            nix.nixPath = [ "nixpkgs=/run/active-nixpkgs-source" ];

            systemd.services.create-nixpkgs-source-link = {
              wantedBy = [ "multi-user.target" ];

              unitConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                RequiresMountsFor = "/run";
              };

              script = ''
                ln -sfT -- ${lib.escapeShellArg "${nixpkgs}"} /run/active-nixpkgs-source
              '';
            };
          };
        })
        { services.resolved.enable = true; }
      ];
    };
  };
}
