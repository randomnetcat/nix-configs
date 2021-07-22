{ config, lib, pkgs, ... }:

{
  imports = [
    ../vendor/impermanence/home-manager.nix
  ];

  options = {
  };

  config = {
    # programs.ssh.enable = true;

    home.persistence."/persist/secrets/randomcat" = {
      directories = [ ".ssh" ];
    };
  };
}
