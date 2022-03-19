{ config, pkgs, lib, ... }:

{
  options = {
    randomcat.tailscale = {
      enable = lib.mkEnableOption "Custom tailscale setup";

      authkeyPath = lib.mkOption {
        type = lib.types.str;
        description = "Path (not nix store path!) to file containing tailscale authkey";
      };
    };
  };

  config = lib.mkIf (config.randomcat.tailscale.enable) {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;

    systemd.services.tailscale-autoconnect = let secretKeyPath = config.randomcat.tailscale.authkeyPath; in {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # otherwise authenticate with tailscale
        ${pkgs.tailscale}/bin/tailscale up -authkey "$(cat -- ${lib.escapeShellArg secretKeyPath})"
      '';

      serviceConfig = {
        ConditionPathExists = secretKeyPath;
      };
    };
  };
}
