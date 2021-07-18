{
  allowUnfree = true;

  packageOverrides = pkgs: {
    nur = import (
      builtins.fetchTarball {
        url = "https://github.com/nix-community/NUR/archive/f32dde0c697cdb11ab2d5b52213f9d069404ee3e.tar.gz";
        sha256 = "111vvv44m5aa4ijz8j8cmj0z0y1dc6a13fw8131njgssifz8h099";
      }
    ) {
      inherit pkgs;
    };
  };
}
