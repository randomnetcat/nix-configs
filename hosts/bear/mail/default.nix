{
  imports = [
    ./config.nix

    ./acme.nix
    ./maddy.nix
  ];

  config = {
    randomcat.services.mail = {
      primaryDomain = "unspecified.systems";

      extraDomains = [
        "randomcat.gay"
        "randomcat.org"
        "jecobb.com"
      ];
    };
  };
}
