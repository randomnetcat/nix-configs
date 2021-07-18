{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "randomcat";
  home.homeDirectory = "/home/randomcat";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  home.packages = [
    pkgs._1password-gui
    pkgs.spotify
    pkgs.discord
    pkgs.gnome3.gnome-tweaks
    pkgs.thunderbird
    pkgs.jetbrains.idea-ultimate
    pkgs.jdk
    pkgs.gradle
  ];

  programs.git = {
    enable = true;
    userEmail = "jason.e.cobb@gmail.com";
    userName = "Jason Cobb";
  };

  dconf.settings = let keybindingMaps = {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Primary><Alt>t";
      command = "gnome-terminal";
      name = "Terimnal";
    };
  };
  in
  {
    "org/gnome/desktop/peripherals/mouse" = {
      "natural-scroll" = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      "natural-scroll" = false;
      "tap-to-click" = true;
      "speed" = 0.25;
      "click-method" = "default";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      "custom-keybindings" = (map (name: "/" + name + "/") (builtins.attrNames keybindingMaps));
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-applications = [ "<Super>Tab" ];
      switch-applications-backward = [ "<Shift><Super>Tab" ];
      switch-windows = [ "<Alt>Tab" ];
      switch-windows-backward = [ "<Shift><Alt>Tab" ];
    };

    "org/gnome/desktop/input-sources" = {
      "xkb-options" = [ "lv3:ralt_alt" ]; # Disable right alt key from being interpreted as special character key
    };
 } // keybindingMaps;

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

    extensions = let addons = pkgs.nur.repos.rycee.firefox-addons; in [
      addons.ublock-origin
      addons.onepassword-password-manager
    ];
  };

  programs.vim = {
    enable = true;
  };
}
