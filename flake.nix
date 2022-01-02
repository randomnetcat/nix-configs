{
  description = "randomcat nixops configurations";

  outputs = { self, nixpkgs }: {
    nixopsConfigurations.default = {
      network.storage.legacy = {};
      inherit nixpkgs;

      oracle-server = import ./hosts/reese;
    };
  };
}
