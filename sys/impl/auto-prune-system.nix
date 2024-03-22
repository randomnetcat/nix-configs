{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.auto-prune-system;
in
{
  options = {
    randomcat.services.auto-prune-system = {
      enable = lib.mkEnableOption "auto-pruning of the system profile";

      calendar = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "The systemd calendar describing how often to prune the system profile.";
      };

      olderThan = lib.mkOption {
        type = lib.types.strMatching "[0-9]+d";
        default = "7d";
        description = "The date limit for versions to keep";
      };

      onBoot = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to prune the system profile on boot.";
      };
    };
  };

  config = {
    systemd.services.auto-prune-system = lib.mkIf cfg.enable {
      wantedBy = lib.mkIf cfg.onBoot [ "multi-user.target" ];
      startAt = cfg.calendar;

      script = ''
        ${config.nix.package}/bin/nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than ${lib.escapeShellArg cfg.olderThan}
      '';

      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
