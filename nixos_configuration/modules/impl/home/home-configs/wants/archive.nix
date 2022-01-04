{ pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.internetarchive
    ];
  };
}
