{ config, lib, pkgs, ... }:

{
  imports = [
    ../nginx.nix
    ./common.nix
  ];

  config = {

    randomcat.services.mastodon = {
      enable = true;
      webDomain = "mastodon.randomcat.org";
      localDomain = "randomcat.org";

      smtp.passwordEncryptedCredFile = ../secrets/mastodon-smtp-pass;

      objectStorage = {
        enable = true;

        aliasHost = "mastodon-files.internetcat.org";
        bucketName = "randomcat-mastodon-personal";
        bucketRegion = "us-east-005";
        bucketHostname = "s3.us-east-005.backblazeb2.com";
        bucketEndpoint = "https://s3.us-east-005.backblazeb2.com";
        encryptedCredFile = ../secrets/mastodon-object-storage-keys;
      };
    };
  };
}
