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
          "browser.ctrlTab.sortByRecentlyUsed" = false;
          "browser.startup.page" = 3;
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.emailtracking.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "dom.private-attribution.submission.enabled" = false;
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
