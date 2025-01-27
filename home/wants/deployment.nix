{ pkgs, inputs, ... }:

{
  config = {
    home.packages = [
      # (pkgs.extend inputs.colmena.overlays.default).colmena
    ];
  };
}
