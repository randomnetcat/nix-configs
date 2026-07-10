{ config, lib, pkgs, nurPkgs, ... }:

let
  profileSettings = {
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
  
  addonsRepo = nurPkgs.nur.repos.rycee.firefox-addons;
  
  commonExtensions = [
    addonsRepo.ublock-origin
    addonsRepo.onepassword-password-manager
  ];
in
{
  config = {
    programs.firefox = {
      enable = true;

      profiles.randomcat = {
        id = 0;
        isDefault = true;
        name = "randomcat";

        settings = profileSettings;

        extensions.packages = commonExtensions ++ [
          addonsRepo.wayback-machine
        ];
      };

      profiles.linda = {
        id = 1;
        isDefault = false;
        name = "Linda";

        settings = profileSettings;
        extensions.packages = commonExtensions;
      };
    };
  };
}
