{ config, lib, pkgs, ... }:

{
  config = {
    randomcat.services.backups = {
      fromNetwork = true;
    };
  };
}
