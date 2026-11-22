{ config, lib, ... }:

let
  types = lib.types;
  cfg = config.randomcat.network;

  hostType = types.submodule ({ name, config, ... }: {
    options = {
      sshKeys = lib.mkOption {
        type = types.listOf types.str;
        description = "The SSH keys (for authentication) for the user";
      };
    };
  });
in
{
  options = {
    randomcat.network = {
      users = lib.mkOption {
        type = types.attrsOf hostType;
        description = "Known users";
      };
    };
  };
}
