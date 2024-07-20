{
  backups = {
    hosts = {
      shaw = {
        destDataset = "nas_oabrke/data/backups";
      };

      reese = {
        syncKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkOFn/HmrUFe3/I8JI4tsRRmTtsjmSjMYruVaxrzmoV";
      };
    };

    movements = [
      {
        sourceHost = "reese";
        targetHost = "shaw";

        datasets = [
          {
            source = "rpool_sggau1/reese/system";
            target = "system";
          }
        ];
      }
    ];
  };
}
