{
  imports = [
    ./wiki

    ../nginx.nix
    ./discord.nix
    ./infinite-redirect.nix
  ];

  config = {
    services.nginx.virtualHosts."infinite.nomic.space" = {
      enableACME = true;
      forceSSL = true;
    };
  };
}
