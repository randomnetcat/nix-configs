#!/usr/bin/env bash

exec nix shell nixpkgs#{htmlq,jq,savepagenow} -c "$(dirname -- "${BASH_SOURCE[0]}")/do-update-plugins.sh"
