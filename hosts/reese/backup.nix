{ config, pkgs, ... }:

{
  imports = [
  ];

  options = {
  };

  config = {
    users.users.backup = {
      isSystemUser = true;
      group = "backup";
      useDefaultShell = true; # Allow SSHing in

      packages = [
        pkgs.mbuffer
        pkgs.pv
        pkgs.zstd
      ];
    };

    users.groups.backup = {};
  };
}
