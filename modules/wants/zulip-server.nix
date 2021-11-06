{ config, pkgs, lib, ... }:

let
  types = lib.types;
  cfg = config.services.randomcat.docker-zulip;
  baseWorkDir = "/opt/docker/zulip";
  secretWorkDir = baseWorkDir + "/secrets";
  secretEnvWorkPath = secretWorkDir + "/zulip.env";
in

{
  options = {
    services.randomcat.docker-zulip = {
      enable = lib.mkEnableOption {
        name = "Docker Zulip instance";
      };

      secrets = {
        rabbitMqPass = lib.mkOption {
          type = types.str;
        };

        postgresPass = lib.mkOption {
          type = types.str;
        };

        memcachedPass = lib.mkOption {
          type = types.str;
        };

        redisPass = lib.mkOption {
          type = types.str;
        };

        zulipSecretKey = lib.mkOption {
          type = types.str;
        };

        emailPassword = lib.mkOption {
          type = types.str;
        };
      };
    };
  };

  config =
    let
      keyNameOf = n: "zulip-secret-${n}";
      composePackage = import ./zulip-detail/adjusted-docker-zulip.nix { inherit pkgs; };
      allKeyServiceNames = map (n: (keyNameOf n) + "-key.service") (lib.attrNames cfg.secrets);
    in
    lib.mkIf (cfg.enable) {
      virtualisation.docker.enable = true;

      users.users.zulip = {
        isSystemUser = true;
        home = "/opt/docker/zulip";
        createHome = true;
        group = "zulip";
        extraGroups = [ "keys" "docker" ];
      };

      users.groups.zulip = {};

      deployment.keys = pkgs.lib.mapAttrs' (n: v: {
        name = keyNameOf n;
        value = {
          text = v;
          user = "zulip";
          group = "zulip";
          permissions = "0640";
        };
      }) cfg.secrets;

      systemd.services.zulip-server = {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = "zulip";
          Group = config.users.users.zulip.group;
        };

        after = allKeyServiceNames;
        requires = allKeyServiceNames;

        script = ''
          set -eu
          set -o pipefail

          echo "Creating secrets work dir..."
          mkdir -p -- ${lib.escapeShellArg secretWorkDir}
          chmod 700 -- ${lib.escapeShellArg secretWorkDir}

          echo "Clearing existing secret env file..."
          rm -f -- ${lib.escapeShellArg secretEnvWorkPath}
          touch -- ${lib.escapeShellArg secretEnvWorkPath}
          chmod 700 -- ${lib.escapeShellArg secretEnvWorkPath}

          echo "Writing secret env file..."
          printf -- "%s" "
          POSTGRES_PW=$(cat /run/keys/${keyNameOf "postgresPass"})
          MEMCACHED_PW=$(cat /run/keys/${keyNameOf "memcachedPass"})
          RABBITMQ_PW=$(cat /run/keys/${keyNameOf "rabbitMqPass"})
          REDIS_PW=$(cat /run/keys/${keyNameOf "redisPass"})
          ZULIP_SECRET_KEY=$(cat /run/keys/${keyNameOf "zulipSecretKey"})
          EMAIL_PASSWORD=$(cat /run/keys/${keyNameOf "emailPassword"})
          " > ${lib.escapeShellArg secretEnvWorkPath}

          echo "Building docker image"
          ${pkgs.docker}/bin/docker compose -f ${composePackage}/docker-compose.yml --env-file ${lib.escapeShellArg secretEnvWorkPath} build

          ${pkgs.docker}/bin/docker compose -f ${composePackage}/docker-compose.yml --env-file ${lib.escapeShellArg secretEnvWorkPath} up
        '';
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "zulip-manage" "${pkgs.docker}/bin/docker compose -f ${composePackage}/docker-compose.yml --env-file ${lib.escapeShellArg secretEnvWorkPath} exec -u zulip zulip /home/zulip/deployments/current/manage.py \"$@\"")
      ];
    };
}
