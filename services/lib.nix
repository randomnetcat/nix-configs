{ config, lib, pkgs, ... }:

{
  options = {
    fountain.lib = lib.mkOption {
      type = lib.types.attrs;
      description = "Helpers for defining configurations (e.g. options).";
      default = {};
    };
  };

  config = {
    fountain.lib = {
      mkCredentialOption = { name, description, nullable ? false }:
        lib.mkOption (({
          description = ''
            Path to encrypted systemd credential named `${name}` (see
            {manpage}`systemd.exec(5)` and {manpage}`systemd-creds(1)`) for
            ${description}.
          '';
          type = (if nullable then lib.types.nullOr else lib.id) lib.types.path;
          example = "/etc/${name}.cred";
        }) // (lib.optionalAttrs nullable {
          default = null;
        }));
    };
  };
}
