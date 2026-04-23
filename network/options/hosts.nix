{ config, lib, ... }:

let
  types = lib.types;
  cfg = config.randomcat.network;

  hostType = types.submodule ({ name, config, ... }: {
    options = {
      hostName = lib.mkOption {
        type = types.uniq types.str;
        description = "The hostname of the host";
        readOnly = true;
      };

      isPortable = lib.mkOption {
        type = types.bool;
        description = "Whether the host is portable and thus might not always be powered on (e.g. a laptop).";
        default = false;
      };

      hostKey = lib.mkOption {
        type = types.nullOr types.str;
        description = "SSH host key of the host";
        default = null;
      };

      tailscaleIP4 = lib.mkOption {
        type = types.str;
        description = "The Tailscale IPv4 address of the host.";
      };

      tailscaleIP6 = lib.mkOption {
        type = types.str;
        description = "The Tailscale IPv6 address of the host.";
      };

      internalDomainName = lib.mkOption {
        type = types.str;
        description = "The domain name for the host in internal DNS.";
        default = "${config.hostName}.${cfg.dns.hostBaseDomain}";
      };
    };

    config = {
      hostName = name;
    };
  });
in
{
  options = {
    randomcat.network = {
      dns = {
        hostBaseDomain = lib.mkOption {
          type = types.str;
          description = "The domain name used for internal DNS.";
        };
      };

      hosts = lib.mkOption {
        type = types.attrsOf hostType;
        description = "The hosts in the network";
      };
    };
  };
}
