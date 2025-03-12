{ config, lib, pkgs, inputs, ... }:

let
  proxyRawGithub' = { path, contentType ? null }: {
    proxyPass = "https://raw.githubusercontent.com/${path}";
    recommendedProxySettings = false;

    extraConfig = ''
      proxy_set_header Host "raw.githubusercontent.com";

      ${lib.optionalString (contentType != null) ''
        proxy_hide_header Content-Type;
        add_header Content-Type "${contentType}";
      ''}
    '';
  };

  proxyRawGithub = path: proxyRawGithub' { inherit path; };
in
{
  config = {
    services.nginx.virtualHosts."randomcat.org" = {
      default = true;

      forceSSL = true;
      enableACME = true;

      # locations."=/" = {
      #   alias = "${./webroot}/index.html";
      # };

      locations."/" = {
        alias = "${./webroot}/";
        tryFiles = "$uri $uri.html $uri/index.html =404";

        extraConfig = ''
          rewrite "^/(.*)/$" "/$1";
        '';
      };

      locations."= /cpp_initialization/initialization.png" = proxyRawGithub "randomnetcat/cpp_initialization/gh-pages/initialization.png";
      locations."= /cpp_initialization/initialization.svg" = proxyRawGithub "randomnetcat/cpp_initialization/gh-pages/initialization.svg";

      locations."/agora-historical-proposals/" = proxyRawGithub "randomnetcat/agora-historical-proposals/gh-pages/";
      locations."= /agora-historical-proposals/".return = "307 https://github.com/randomnetcat/agora-historical-proposals";

      locations."= /cpp_next/specification/launder_arrays" = proxyRawGithub' {
        path = "randomnetcat/cpp_next/refs/heads/gh-pages/specification/launder_arrays.html";
        contentType = "text/html";
      };

      locations."= /cpp_next/specification/launder_arrays.html".return = "308 /cpp_next/specification/launder_arrays";

      locations."= /assessor-thesis".return = "308 /assessor-thesis/";

      locations."/assessor-thesis/" = {
        # Trailing / is necessary
        alias = "${inputs.assessor-thesis.packages.${pkgs.buildPlatform.system}.site}/";
        index = "index.html";
      };

      locations."/assessor-thesis/statistics/" = {
        # Trailing / is necessary
        alias = "${inputs.assessor-thesis.packages.${pkgs.buildPlatform.system}.site}/statistics/";

        extraConfig = ''
          autoindex on;
        '';
      };

      locations."= /cases" = {
        # Use rewrite to ensure query arguments are preserved.
        extraConfig = ''
          rewrite "^/cases$" "https://agoranomic.org/cases/";
        '';
      };

      locations."/cases/" = {
        # Use rewrite to ensure query arguments are preserved.
        extraConfig = ''
          rewrite "^/cases/(.*)$" "https://agoranomic.org/cases/$1";
        '';
      };
    };
  };
}
