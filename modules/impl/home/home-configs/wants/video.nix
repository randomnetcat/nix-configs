{ pkgs, ... }:

{
  config = {
    home.packages = [
      pkgs.obs-studio
    ];
  };
}
