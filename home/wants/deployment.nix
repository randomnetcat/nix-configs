{ pkgs, inputs, ... }:

{
  config = {
    home.packages = [
      # Currently broken because of https://git.lix.systems/lix-project/nix-eval-jobs/pulls/14
      # (pkgs.extend inputs.colmena.overlays.default).colmena
    ];
  };
}
