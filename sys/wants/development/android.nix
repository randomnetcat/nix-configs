{ config, lib, pkgs, ... }:

{
  config = {
    programs.adb.enable = true;
  };
}
