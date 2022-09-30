{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
