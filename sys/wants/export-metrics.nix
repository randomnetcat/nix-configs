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

    systemd.services.export-metrics-proxy = 
      let
        dependencyUnits = lib.mkIf cfg.tailscaleOnly [
          "tailscaled.service"
          "tailscale-autoconnect.service"
        ];
      in
      {
        bindsTo = [ "nginx.service" ];
        requires = [ "export-metrics-proxy.socket" ];
        wants = dependencyUnits;
        after = lib.mkMerge [
          [ "export-metrics-proxy.socket" "nginx.service" ]
          dependencyUnits
        ];

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

    systemd.sockets.export-metrics-proxy = {
      wantedBy = [ "sockets.target" ];

      socketConfig = {
        Accept = false;
        ListenStream = cfg.port;
        BindIPv6Only = "both";
        BindToDevice = lib.mkIf (cfg.listenInterface != null) cfg.listenInterface;
      };
    };
  };
}
