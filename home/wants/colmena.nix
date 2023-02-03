{ config, lib, pkgs, inputs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    home.packages = [
      ((pkgs.extend inputs.colmena.overlays.default).colmena)
    ];
  };
}
