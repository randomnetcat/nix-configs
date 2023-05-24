{ config, lib, pkgs, ...}:

{
  config = {
    services.httpd.enable = true;
    services.httpd.adminAddr = "webmaster@example.org";
    services.httpd.enablePHP = true;
    services.httpd.phpPackage = pkgs.php81.buildEnv {
      extraConfig = ''
        include_path=".:/var/www/_include"
        display_errors=On
        log_errors=On
        error_log=/var/log/httpd/php_error.log
        upload_max_filesize=20M
        post_max_size=20M
      '';
    };

    services.httpd.virtualHosts.localhost = rec {
      documentRoot = "/var/www/wolftech";
      locations."/".index = "index.php index.html";

      extraConfig = ''
        <Directory "${documentRoot}">
          AllowOverride All
        </Directory>
      '';
    };
  };
}
