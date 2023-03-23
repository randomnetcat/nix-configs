{ config, lib, pkgs, ... }:

{
  imports = [
    ./general-development.nix
  ];

  options = {
  };

  config = {
    home.enableDebugInfo = true;

    home.packages = [
      pkgs.jetbrains.clion
    ];

    home.file."dev/cpp/gcc".source = pkgs.gcc;
    home.file."dev/cpp/clang".source = pkgs.clang;
    home.file."dev/cpp/cmake".source = pkgs.cmake;
  };
}
