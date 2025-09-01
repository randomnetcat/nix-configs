{ config, lib, pkgs, nurPkgs, ... }:

{
  config = {
    programs.firefox = {
      enable = true;

      profiles.randomcat = {
        id = 0;
        isDefault = true;
        name = "randomcat";

        settings = {
          # Configuration
          "browser.ctrlTab.sortByRecentlyUsed" = false;
          "browser.startup.page" = 3;

          # Privacy settings
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.emailtracking.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "dom.private-attribution.submission.enabled" = false;

          # AI settings
          "browser.ml.enable" = false;
          "browser.ml.chat.enabled" = false;
        };

        extensions.packages =
          let
            addons = nurPkgs.nur.repos.rycee.firefox-addons;
          in
          [
            addons.ublock-origin
            addons.onepassword-password-manager
            addons.wayback-machine
          ];
      };
    };
  };
}
