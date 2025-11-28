{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.configuration-time-metric;
in
{
  options = {
    randomcat.services.configuration-time-metric = {
      enable = lib.mkEnableOption "metric for the time the current system configuration was deployed";
    };
  };
  
  config = lib.mkIf cfg.enable {
    randomcat.services.periodic-metrics = {
      enable = true;

      collectors.configuration-time.script = ''
        echo "# HELP nixos_configuration_timestamp_seconds The time the current system configuration was deployed."
        echo "# TYPE nixos_configuration_timestamp_seconds gauge"
        echo "nixos_configuration_timestamp_seconds $(stat -c '%Y' /nix/var/nix/profiles/system)"
      '';
    };
  };
}
