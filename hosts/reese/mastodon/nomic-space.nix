{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    randomcat.mastodon-containers.instances.nomic-space = {
      enable = true;
      containerName = "mdn-nomic"; # this needs to be no longer than 13 characters apparently
      webDomain = "mastodon.nomic.space";
      localDomain = "nomic.space";
    };
  };
}
