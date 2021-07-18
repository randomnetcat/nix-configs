{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {};

  config = {
    programs.vim = {
      enable = true;
    };
  };
}
