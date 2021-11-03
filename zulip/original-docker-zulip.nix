{ pkgs ? import <nixpkgs> {} }:

pkgs.fetchFromGitHub {
  owner = "zulip";
  repo = "docker-zulip";
  rev = "f680f3a8a0ebdd8dbe82ee287bd9391d1e293779";
  sha256 = "0sn66zg2pk94r41zwh4x5gkgr62k3x6n668xylcivw6l738fr4gv";
}
