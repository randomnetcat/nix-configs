{ config, lib, pkgs, nurPkgs, ... }:

{
  config = {
    home.packages = [
      pkgs._1password-gui
    ];

    nixpkgs.config.allowUnfree = true;

    programs.firefox = {
      enable = true;

      profiles.randomcat = {
        id = 0;
        isDefault = true;
        name = "randomcat";

        settings = {
          "browser.ctrlTab.sortByRecentlyUsed" = false;
          "browser.startup.page" = 3;
        };
      };

      extensions =
        let addons = nurPkgs.nur.repos.rycee.firefox-addons;
        in
        [
          addons.ublock-origin
          addons.onepassword-password-manager
          addons.wayback-machine
        ];
    };
  };
}
