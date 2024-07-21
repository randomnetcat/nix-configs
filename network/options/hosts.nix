{ config, lib, ... }:

let
  types = lib.types;

  hostType = types.submodule ({ name, ... }: {
    options = {
      hostName = lib.mkOption {
        type = types.str;
        description = "The hostname of the host";
      };

      hostKey = lib.mkOption {
        type = types.nullOr types.str;
        description = "SSH host key of the host";
        default = null;
      };
    };

    config = {
      hostName = name;
    };
  });
in
{
  options = {
    randomcat.network = {
      hosts = lib.mkOption {
        type = types.attrsOf hostType;
        description = "The hosts in the network";
      };
    };
  };
}
