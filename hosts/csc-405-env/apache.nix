{ config, lib, pkgs, inputs, ...}:

{
  config = {
    services.httpd.enable = true;
    services.httpd.adminAddr = "webmaster@example.org";
    services.httpd.enablePHP = true;
    services.httpd.phpPackage = inputs.phps.packages."${pkgs.system}".php56.buildEnv {
      extraConfig = ''
        display_errors=Off
        log_errors=On
        error_log=/var/log/httpd/php_error.log
        upload_max_filesize=20M
        post_max_size=20M
        request_order=GP
        variables_order=GPCS
        session.save_path=/var/lib/php/session-5.6
      '';
    };

    services.httpd.virtualHosts.localhost = rec {
      documentRoot = "/var/www/html";
      locations."/".index = "index.php index.html";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/php 700 wwwrun wwwrun - -"
      "d /var/lib/php/session-5.6 700 wwwrun wwwrun - -"
    ];
  };
}
