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

    working-nixops-nixpkgs = {
      url = "github:nixos/nixops?rev=65b70fbe4c3a942a266794e28a08147b06ebb6bc";
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, working-nixops-nixpkgs }: {
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

            nixopsPkgs = import working-nixops-nixpkgs {
              system = "x86_64-linux";
            };
          };
        }
      ];
    };
  };
}
