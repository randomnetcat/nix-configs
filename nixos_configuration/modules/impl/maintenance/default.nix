{ pkgs, lib, ... }:

{
  config = {
    nix.gc.automatic = true;
    nix.optimise.automatic = true;

    services.fstrim.enable = true;
  };
}
