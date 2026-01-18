{ config, lib, pkgs, ... }:

let
  blurayJava = pkgs.jdk17;

  rawVlc = pkgs.vlc.override {
    libbluray-full = pkgs.libbluray-full.override {
      libbluray = pkgs.libbluray.override {
        withAACS = true;
        withBDplus = true;
        jdk21_headless = blurayJava;
      };
    };
  };

  # libbluray breaks with Java that is too recent. (It appears that it pokes around in JDK
  # internals that have since changed.) As a workaround, set JAVA_HOME when using VLC
  # to a known-compatible JDK version.
  wrappedVlc = rawVlc.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

    postFixup = ''
      ${oldAttrs.postFixup or ""}

      for program in "$out"/bin/*; do
        wrapProgram "$program" --set JAVA_HOME ${lib.escapeShellArg blurayJava.home}
      done
    '';
  });
in
{
  home.packages = [
    pkgs.strawberry
    pkgs.makemkv
    pkgs.helvum
    pkgs.jellyfin-media-player
    wrappedVlc
  ];
}
