{ pkgs, lib, ... }:

{
  options = {
    randomcat.services.mail = { 
      primaryDomain = lib.mkOption {
        type = lib.types.str;
        description = "Primary mail domain name";
      };

      extraDomains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Extra mail domain names";
        default = [];
      };
    };
  };
}
