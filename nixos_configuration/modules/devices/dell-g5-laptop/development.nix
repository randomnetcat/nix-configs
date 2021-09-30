{ config, pkgs, ... }:

{
  imports = [
    ./mounts/feature/projects.nix
  ];

  options = {
  };

  config = {
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
