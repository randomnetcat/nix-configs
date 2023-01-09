{ config, lib, pkgs, ... }:

{
  config = {
    users.users.insecure = {
      isNormalUser = true;
    };
  };
}
