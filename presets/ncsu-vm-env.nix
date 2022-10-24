{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./vm-env.nix
  ];

  config = {
    home-manager.users.randomcat.imports = map (x: ../home/wants + "/${x}.nix") [
      "general-development"
    ] ++ [
      ../home/id/ncsu.nix
    ];
  };
}
