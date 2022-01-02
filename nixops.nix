{
  network = {
    storage.legacy = {};

    nixpkgs = import <nixpkgs> {};
  };

  oracle-server = import ./hosts/reese;
 }
