{ pkgs, lib, config, ... }:

{
  config = {
    environment.systemPackages = [ pkgs.dbeaver ];

    services.mysql.enable = true;
    services.mysql.package = pkgs.mysql80;

    services.mysql.ensureUsers = [
      {
        name = "randomcat";
        ensurePermissions = {
          "*.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
