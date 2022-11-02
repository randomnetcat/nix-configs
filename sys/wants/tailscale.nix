{ config, pkgs, lib, ... }:

{
  options = {
    randomcat.services.tailscale = {
      enable = lib.mkEnableOption "Custom tailscale setup";

      authkeyPath = lib.mkOption {
        type = lib.types.str;
        description = "Path (not nix store path!) to file containing tailscale authkey";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Extra command line arguments to tailscale";
      };
    };
  };

  config = lib.mkIf (config.randomcat.services.tailscale.enable) {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;

    # Tailscale complains about this
    networking.firewall.checkReversePath = "loose";

    # Allow tailscale devices access to all ports (since tailscale will enforce this)
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    systemd.services.tailscale-autoconnect = let secretKeyPath = config.randomcat.services.tailscale.authkeyPath; in {
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
        ${pkgs.tailscale}/bin/tailscale up -authkey "$(cat -- ${lib.escapeShellArg secretKeyPath})" ${lib.escapeShellArgs config.randomcat.services.tailscale.extraArgs}
      '';

      serviceConfig = {
        ConditionPathExists = secretKeyPath;
      };
    };
  };
}
