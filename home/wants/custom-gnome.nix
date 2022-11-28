{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    dconf.settings = let keybindingMaps = {
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Primary><Alt>t";
        command = "kgx";
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
        "disable-while-typing" = false;
        "two-finger-scrolling-enabled" = true;
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

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
      };

      "org/gnome/desktop/session" = {
        "idle-delay" = 300;
      };

      "org/gnome/desktop/sound" = {
        "allow-volume-above-100-percent" = true;
      };

      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "org.gnome.Console.desktop"
          "firefox.desktop"
          "discord.desktop"
          "thunderbird.desktop"
        ];
      };
    } // keybindingMaps;
  };
}
