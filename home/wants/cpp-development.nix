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

    home.file."dev/toolchains/cpp/gcc".source = pkgs.gcc;
    home.file."dev/toolchains/cpp/clang".source = pkgs.clang;
    home.file."dev/toolchains/cpp/cmake".source = pkgs.cmake;
  };
}
