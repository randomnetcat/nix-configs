{ config, lib, pkgs, ... }:

let
  sourceCfg = config.randomcat.services.backups.source;
  cfg = sourceCfg.ssh;

  targetsList = lib.attrValues sourceCfg.acceptTargets;
  acceptsAnyTargets = (lib.length targetsList) != 0;
  actuallyEnabled = cfg.enable && (lib.length cfg.addresses) != 0 && acceptsAnyTargets;

  acceptedUsers = lib.naturalSort (lib.unique (map (target: target.user) targetsList));

  hostName = config.networking.hostName;
  randomcatAddresses = let host = config.randomcat.network.hosts."${hostName}" or { }; in [ (host.tailscaleIP4 or null) (host.tailscaleIP6 or null) ];
  birdsongAddresses = let host = config.birdsong.hosts."${hostName}" or { }; in [ (host.ipv4 or null) (host.ipv6 or null) ];

  vpnAddresses = lib.filter (ip: ip != null) (randomcatAddresses ++ birdsongAddresses);
in
{
  imports = [
    ../../impl/ssh-security.nix
  ];

  options = {
    randomcat.services.backups.source.ssh = {
      enable = lib.mkEnableOption "SSH configuration for backup source";
      enableVpnAddresses = lib.mkEnableOption "listening on randomcat and birdsong VPN addresses for backups";

      port = lib.mkOption {
        type = lib.types.port;
        description = "The port to listen on for backup SSH connections.";
        default = 2222;
      };

      addresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "The IP addresses to listen on for backup SSH connections.";
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    randomcat.services.backups.source.ssh.addresses = lib.mkIf cfg.enableVpnAddresses vpnAddresses;

    services.openssh = lib.mkIf actuallyEnabled {
      enable = true;

      listenAddresses = map
        (ip: {
          addr = "[${ip}]";
          port = cfg.port;
        })
        cfg.addresses;

      # Since we use Match, and not all directives can follow a Match directive (even Match All), use mkAfter to
      # try to avoid issues.
      extraConfig = lib.mkAfter ''
        Match LocalPort ${toString cfg.port}
        AllowUsers ${lib.concatStringsSep "," acceptedUsers}

        Match All
      '';
    };

    systemd.services.sshd = lib.mkIf (actuallyEnabled && cfg.enableVpnAddresses) {
      wants = [ "tailscale-autoconnect.service" "wireguard-${config.birdsong.peering.interface}.service" ];
      after = [ "tailscale-autoconnect.service" "wireguard-${config.birdsong.peering.interface}.service" ];
    };
  };
}
