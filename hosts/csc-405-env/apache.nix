{ config, lib, pkgs, ...}:

{
  config = {
    services.httpd.enable = true;
    services.httpd.adminAddr = "webmaster@example.org";
    services.httpd.enablePHP = true;
    services.httpd.phpPackage = pkgs.php81.buildEnv {
      extraConfig = ''
        include_path=".:/var/www/_include"
        display_errors=Off
        log_errors=On
        error_log=/var/log/httpd/php_error.log
        upload_max_filesize=20M
        post_max_size=20M
        request_order=GP
        variables_order=GPCS
        session.save_path=/var/lib/php/session
      '';
    };

    services.httpd.virtualHosts.localhost = rec {
      documentRoot = "/var/www";
      locations."/".index = "index.php index.html";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/php 700 wwwrun wwwrun - -"
      "d /var/lib/php/session 700 wwwrun wwwrun - -"
    ];
  };
}
