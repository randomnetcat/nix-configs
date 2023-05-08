{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    time.timeZone = "UTC";

    home-manager.users.root.imports = map (x: ../home/wants + "/${x}.nix") [
      "custom-terminal"
    ] ++ [
      ({ pkgs, lib, ... }: {
        _module.args.inputs = inputs;

        programs.vim.packageConfigurable = pkgs.vim;
      })
    ];

    # Simple security things
    # From https://xeiaso.net/blog/paranoid-nixos-2021-07-18
    networking.firewall.enable = true;
    nix.settings.allowed-users = [ "root" ];
    security.sudo.execWheelOnly = true;
  };
}
