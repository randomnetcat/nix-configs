{
  description = "randomcat nixops configurations";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";

  inputs.agorabot-prod = {
    url = "github:randomnetcat/AgoraBot/main";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.agorabot-secret-hitler = {
    url = "github:randomnetcat/AgoraBot/secret-hitler";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, agenix, agorabot-prod, agorabot-secret-hitler }: {
    nixopsConfigurations.default = {
      network.storage.legacy = {};
      inherit nixpkgs;

      oracle-server = { pkgs, config, ... }: {
        imports = [
          ./hosts/reese
          agenix.nixosModule
        ];

        config = {
          services.randomcat.agorabot-server.instances = {
            agora-prod.package = (pkgs.extend agorabot-prod.overlays.default).randomcat.agorabot;
            secret-hitler.package = (pkgs.extend agorabot-secret-hitler.overlay).randomcat.agorabot;
          };
        };
      };
    };
  };
}
