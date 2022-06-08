{ config, lib, pkgs, ...}:

{
  config = {
    services.httpd.enable = true;
    services.httpd.adminAddr = "webmaster@example.org";
    services.httpd.enablePHP = true;
    services.httpd.phpPackage = pkgs.php81.buildEnv {
      extraConfig = ''
        include_path=".:/var/www/wolftech/_include"
      '';
    };

    services.httpd.virtualHosts.localhost = {
      documentRoot = "/var/www/wolftech";
    };
  };
}
