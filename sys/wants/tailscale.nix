{ config, pkgs, lib, ... }:

{
  options = {
    randomcat.services.tailscale = {
      enable = lib.mkEnableOption "Custom tailscale setup";

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Extra command line arguments to tailscale";
        default = [];
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

    # Open UDP port to help establishing direct WireGuard connections
    networking.firewall.allowedUDPPorts = [ 41641 ];

    systemd.services.tailscale-autoconnect = {
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
        ${pkgs.tailscale}/bin/tailscale up ${lib.escapeShellArgs config.randomcat.services.tailscale.extraArgs}
      '';
    };
  };
}
