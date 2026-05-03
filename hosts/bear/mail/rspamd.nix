{ config, lib, pkgs, ... }:

{
  config = {
    services.rspamd = {
      enable = true;

      workers = {
        controller = {};

        normal = {
          bindSockets = [
            "127.0.0.1:11333"
          ];
        };
      };

      locals = {
        "actions.conf".text = ''
          reject = 99999;
          add_header = 10;
          greylist = 4;
        '';

        "redis.conf".text = ''
          servers = "${config.services.redis.servers.rspamd.unixSocket}";
        '';
      };
    };

    services.redis.servers.rspamd = {
      enable = true;
      port = 0;
      user = config.services.rspamd.user;
    };
  };
}
