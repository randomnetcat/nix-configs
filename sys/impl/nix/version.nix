{ pkgs, lib, ... }:

{
  config = {
    nix = {
      # 2.21.0 is broken apparently? https://github.com/NixOS/nix/issues/10238
      # So, use 2.20 instead of 2.21.0. This will disable itself when any version after 2.21.0 is released.
      package = if pkgs.nixVersions.unstable.version == "2.21.0" then pkgs.nixVersions.nix_2_20 else pkgs.nixVersions.unstable;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
  };
}
