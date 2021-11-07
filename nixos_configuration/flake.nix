{
  outputs = { self, nixpkgs }: {
    nixosConfigurations.randomcat-laptop-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
