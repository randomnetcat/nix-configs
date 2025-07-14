{ config, lib, pkgs, ... }:

let
  cfg = config.randomcat.services.export-metrics;
  inherit (lib) types;

  socketName = "/run/nginx/randomcat-export-metrics.sock";
in
{
  options = {
    randomcat.services.export-metrics = {
      enable = lib.mkEnableOption "exporting Prometheus metrics to the network";

      listenInterface = lib.mkOption {
        type = types.nullOr types.str;
        description = "The network interface to listen on.";
        default = null;
      };

      tailscaleOnly = lib.mkEnableOption "exporting Prometheus metrics on Tailscale only";

      port = lib.mkOption {
        type = types.port;
        description = "The port to expose all metrics on.";
        default = 9098;
      };

      exports = lib.mkOption {
        type = types.attrsOf (types.submodule ({ lib, name, ... }: {
          options = {
            name = lib.mkOption {
              type = types.str;
              description = "The name of the exporter.";
              default = name;
            };

            localPort = lib.mkOption {
              type = types.nullOr types.port;
              description = "The port that the exporter is listening on locally. If enableService is set, this must not be set and will automatically be the port of the underlying exporter.";
              default = null;
            };

            enableService = lib.mkOption {
              type = types.bool;
              description = "Whether to enable the underlying service in services.prometheus.exporters.";
              default = true;
            };
          };
        }));
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = map
      ({ name, value }: {
        assertion = value.enableService -> value.localPort == null;
        message = "In randomcat.services.export-metrics.exports.${name}: localPort must not be set if enableService is true.";
      })
      (lib.attrsToList cfg.exports);

    randomcat.services.export-metrics.listenInterface = lib.mkIf (cfg.tailscaleOnly) config.services.tailscale.interfaceName;

    services.prometheus.exporters = lib.mkMerge (map
      (value: {
        "${value.name}" = {
          enable = true;

          # We are exporting here. So, by default, there should be no reason to allow these metrics to be accessed anywhere else.
          listenAddress = lib.mkDefault "127.0.0.1";
        };
      })
      (lib.filter (value: value.enableService) (lib.attrValues cfg.exports)));

    services.nginx = {
      enable = true;

      virtualHosts."export-metrics" = {
        listen = [
          {
            addr = "unix:${socketName}";
          }
        ];

        default = true;

        locations = lib.mkMerge (map
          (value: {
            "=/export-metrics/${value.name}" = {
              recommendedProxySettings = true;
              proxyPass = "http://127.0.0.1:${toString (if value.enableService then config.services.prometheus.exporters."${value.name}".port else value.localPort)}/metrics";
            };
          })
          (lib.attrValues cfg.exports));
      };
    };

    systemd.services.export-metrics-proxy = {
      bindsTo = [ "nginx.service" ];
      requires = [ "export-metrics-proxy.socket" ];
      after = [ "export-metrics-proxy.socket" "nginx.service" ];

      unitConfig = {
        JoinsNamespaceOf = "nginx.service";
      };

      serviceConfig = {
        DynamicUser = true;
        RuntimeDirectory = "export-metrics-proxy";
        RuntimeDirectoryMode = "0700";

        # Ensure the service has access to the socket that nginx is listening on.
        BindPaths = "${socketName}:/run/export-metrics-proxy/target.sock";

        Type = "exec";
        ExecStart = "${lib.getLib config.systemd.package}/lib/systemd/systemd-socket-proxyd /run/export-metrics-proxy/target.sock";

        CapabilityBoundingSet = "";
        LockPersonality = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        PrivateDevices = true;
        PrivateNetwork = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = true;
        RestrictAddressFamilies = "AF_UNIX";
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" ];
        UMask = "077";
      };
    };

    systemd.sockets.export-metrics-proxy = lib.mkMerge [
      {
        # We sometimes set DefaultDependencies=no below, so always ensure we
        # have at least some ordering with the rest of startup.
        wantedBy = [ "multi-user.target" ];
        before = [ "multi-user.target" ];

        socketConfig = {
          Accept = false;
          ListenStream = cfg.port;
          BindIPv6Only = "both";
          BindToDevice = lib.mkIf (cfg.listenInterface != null) cfg.listenInterface;
        };
      }

      (lib.mkIf cfg.tailscaleOnly {
        unitConfig = {
          # We have to start late in boot because the tailscale0 interface is
          # not available until tailscaled runs. tailscaled is a normal system
          # service, so it starts after basic.target. basic.taget pulls in
          # sockets.target, and, by default, we will have
          # Before=sockets.target. This causes a circular dependency.
          #
          # This isn't a service that is used locally on the system and isn't
          # required early in boot, so we just remove the dependency to solve
          # the ordering issue.
          DefaultDependencies = false;
        };

        # Here, we are sure to include all DefaultDependencies other than
        # Before=sockets.target.

        requires = [ "sysinit.target" ];
        bindsTo = [ "tailscaled.service" ];

        after = [
          "sysinit.target"
          "tailscaled.service"
        ];

        before = [ "shutdown.target" ];
        conflicts = [ "shutdown.target" ];
      })
    ];
  };
}
