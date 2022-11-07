{ config, lib, pkgs, ... }:

{
  imports = [
    ../nginx.nix
    ./common.nix
  ];

  config = {
    randomcat.mastodon-containers.instances.personal = {
      enable = true;
      containerName = "mastodon"; # Legacy
      webDomain = "mastodon.randomcat.org";
      localDomain = "randomcat.org";
    };
  };
}
