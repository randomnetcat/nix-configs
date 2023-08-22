{ ... }:

{
  config = {
    system.autoUpgrade = {
      enable = true;
      flake = "github:randomnetcat/nix-configs";
    };
  };
}
