{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    home.packages = [ pkgs.nixopsUnstable ];
  };
}
