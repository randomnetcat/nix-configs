{
  outputs = { self, nixpkgs }: {
    nixosConfigurations.randomcat-laptop-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ (import ./configuration.nix { deviceDir = ./modules/devices/dell-g5-laptop; }) ];
    };
  };
}
