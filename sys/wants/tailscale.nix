{ config, pkgs, lib, ... }:

{
  options = {
    randomcat.services.tailscale = {
      enable = lib.mkEnableOption "Custom tailscale setup";

      ssh = lib.mkEnableOption "Tailscale SSH";

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Extra command line arguments to tailscale";
        default = [ ];
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
        patches = lib.filter (p: (p.url or "") != "https://github.com/tailscale/tailscale/commit/2889fabaefc50040507ead652d6d2b212f476c2b.patch") (old.patches or [ ]);
      }));
    };

    randomcat.services.tailscale.extraArgs = lib.mkIf config.randomcat.services.tailscale.ssh [ "--ssh" ];

    # Allow devices connecting over Tailscale to access all ports (since Tailscale will enforce its own ACLs).
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      after = [ "tailscaled.service" "network-online.target" ];
      requires = [ "tailscaled.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
      };

      script = with pkgs; ''
        # Wait for tailscaled to settle.
        sleep 2

        ${lib.getExe config.services.tailscale.package} up --reset ${lib.escapeShellArgs config.randomcat.services.tailscale.extraArgs}
      '';
    };
  };
}
