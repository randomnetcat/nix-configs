{ config, lib, pkgs, ... }:

{
  config = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
