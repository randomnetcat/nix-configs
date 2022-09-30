{ pkgs, lib, ... }:

{
  config = {
    nix = {
      package = pkgs.nixVersions.unstable;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
  };
}
