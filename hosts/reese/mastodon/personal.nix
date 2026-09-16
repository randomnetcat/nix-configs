{ config, lib, pkgs, ... }:

{
  imports = [
    ../nginx.nix
    ./common.nix
  ];

  config = {
    services.mastodon.package = lib.mkIf (lib.versionOlder pkgs.mastodon.version "4.6.8") (
      pkgs.mastodon.override {
        srcOverride = pkgs.fetchFromGitHub {
          owner = "mastodon";
          repo = "mastodon";
          rev = "v4.6.8";
          hash = "sha256-fDbQunhcpnMnIufEX2oRH9vulsHjtlR95boj0M2O3CQ=";
          passthru = {
            version = "4.6.8";
            yarnHash = "sha256-VlOG91ZuO+1UXTbtwIrYUbqHjmSfPSfLhrf4TxCJqJ0=";
            yarnMissingHashes = pkgs.mastodon.src.passthru.yarnMissingHashes;
          };
        };
      }
    );

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
