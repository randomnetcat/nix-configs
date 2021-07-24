{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    services.duplicati = {
      enable = true;
      user = "root";
    };


    users.users.duplicati = {
      isSystemUser = true;
      uid = config.ids.uids.duplicati;
      home = "/var/lib/duplicati";
      createHome = true;
      group = "duplicati";
    };
  };
}
