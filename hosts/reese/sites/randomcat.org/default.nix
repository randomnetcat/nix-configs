{ config, lib, pkgs, ... }:

let
  proxyRawGithub = path: {
    proxyPass = "https://raw.githubusercontent.com/${path}";
    recommendedProxySettings = false;

    extraConfig = ''
      proxy_set_header Host "raw.githubusercontent.com";
    '';
  };
in
{
  config = {
    services.nginx.virtualHosts."randomcat.org" = {
      default = true;

      forceSSL = true;
      enableACME = true;

      locations."/".return = "307 https://randomnetcat.github.io$request_uri";

      locations."= /cpp_initialization/initialization.png" = proxyRawGithub "randomnetcat/cpp_initialization/gh-pages/initialization.png";
      locations."= /cpp_initialization/initialization.svg" = proxyRawGithub "randomnetcat/cpp_initialization/gh-pages/initialization.svg";

      locations."/agora-historical-proposals/" = proxyRawGithub "randomnetcat/agora-historical-proposals/gh-pages/";
      locations."= /agora-historical-proposals/".return = "307 https://github.com/randomnetcat/agora-historical-proposals";
    };
  };
}
