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

      objectStorage = {
        enable = true;

        aliasHost = "mastodon-files.randomcat.org";
        bucketName = "randomcat-mastodon-personal";
        bucketRegion = "us-east-005";
        bucketHostname = "s3.us-east-005.backblazeb2.com";
        encryptedKeyFile = ../secrets/mastodon-personal-s3;
      };
    };
  };
}
