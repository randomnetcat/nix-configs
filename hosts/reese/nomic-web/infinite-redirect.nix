{
  config = {
    services.nginx.virtualHosts."infinitenomic.randomcat.org" = {
      enableACME = true;
      forceSSL = true;

      locations."/".return = "308 https://infinite.nomic.space$request_uri";
    };
  };
}
