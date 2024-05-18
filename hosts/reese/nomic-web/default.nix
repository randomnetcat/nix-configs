{
  imports = [
    ../nginx.nix
    ./wiki.nix
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
