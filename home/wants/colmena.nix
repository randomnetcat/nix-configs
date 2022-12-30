{ config, lib, pkgs, inputs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    home.packages = [
      inputs.colmena.packages."${pkgs.targetPlatform.system}".colmena
    ];
  };
}
