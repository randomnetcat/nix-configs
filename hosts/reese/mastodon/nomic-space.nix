{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    randomcat.mastodon-containers.instances.nomic-space = {
      enable = true;
      webDomain = "mastodon.nomic.space";
      localDomain = "nomic.space";
    };
  };
}
