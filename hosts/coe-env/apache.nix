{ config, lib, pkgs, ...}:

{
  config = {
    services.httpd.enable = true;
    services.httpd.adminAddr = "webmaster@example.org";
    services.httpd.enablePHP = true;
    services.httpd.phpPackage = pkgs.php81.buildEnv {
      extraConfig = ''
        include_path=".:/var/www/wolftech/_include"
        display_errors=Off
        log_errors=On
        error_log=/var/log/httpd/php_error.log
      '';
    };

    services.httpd.virtualHosts.localhost = {
      documentRoot = "/var/www/wolftech";
    };
  };
}
