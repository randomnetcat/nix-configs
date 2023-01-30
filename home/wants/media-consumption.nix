{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.strawberry
  ];
}
