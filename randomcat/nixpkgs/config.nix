{
  allowUnfree = true;

  packageOverrides = pkgs: {
    nur = import (
      builtins.fetchTarball {
        url = "https://github.com/nix-community/NUR/archive/636db635d740d8b6e7e3f477d3c7525fb520a37c.tar.gz";
        sha256 = "0l7g86xac6c2g06jdilmlybc5lfxpi1n6xcf1g2v7x6jw588bfyy";
      }
    ) {
      inherit pkgs;
    };
  };
}
