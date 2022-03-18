{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "custom-docker-zulip";
  version = "0.0.1";

  src = import ./original-docker-zulip.nix { inherit pkgs; };

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];

  buildPhase = ''
    cp ${./new-docker-compose.yml} docker-compose.yml
    cp ${./new-entrypoint.sh} entrypoint.sh
  '';

  installPhase = ''
    cp -R . "$out"
  '';
}
