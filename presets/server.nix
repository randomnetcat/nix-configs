{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    home-manager.users.root.imports = map (x: ../home/wants + "/${x}.nix") [
      "custom-terminal"
    ] ++ [
      ({ pkgs, lib, ... }: {
        _module.args.inputs = inputs;

        programs.vim.packageConfigurable = pkgs.vim;
      })
    ];
  };
}
