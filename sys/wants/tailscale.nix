{ config, pkgs, lib, ... }:

{
  options = {
    randomcat.services.tailscale = {
      enable = lib.mkEnableOption "Custom tailscale setup";

      ssh = lib.mkEnableOption "Tailscale SSH";

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Extra command line arguments to tailscale";
        default = [];
      };
    };
  };

  config = lib.mkIf (config.randomcat.services.tailscale.enable) {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      openFirewall = config.services.tailscale.port > 0;

      # NixOS attempts to add systemd hardening, but this interfers with
      # creating shells for Tailscale SSH. So, for the moment, forcibly disable
      # this.
      package = lib.mkIf config.randomcat.services.tailscale.ssh (pkgs.tailscale.overrideAttrs (old: {
        patches = lib.filter (p: (p.url or "") != "https://github.com/tailscale/tailscale/commit/2889fabaefc50040507ead652d6d2b212f476c2b.patch") (old.patches or []);
      }));
    };

    randomcat.services.tailscale.extraArgs = lib.mkIf config.randomcat.services.tailscale.ssh [ "--ssh" ];

    # Allow tailscale devices access to all ports (since tailscale will enforce this)
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];

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
