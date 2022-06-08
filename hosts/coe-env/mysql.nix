{ config, lib, pkgs, ...}:

{
  config = {
    services.mysql.enable = true;
    services.mysql.package = pkgs.mariadb;
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
