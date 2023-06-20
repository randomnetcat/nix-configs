{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.strawberry

    (pkgs.vlc.override {
      libbluray = pkgs.libbluray.override {
        withAACS = true;
        withBDplus = true;
        withJava = true;
        jdk = pkgs.jdk11;
      };
    })
  ];
}
