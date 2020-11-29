#!/usr/bin/env bash
set -euo pipefail
export NIX_PATH=channel:nixos-20.09

echo "Test with attribute name"
./nix-bundle.sh hello /bin/hello

echo "Test with store path"
out=$(nix-build --no-out-link --expr '(import <nixpkgs> {})' -A hello)
./nix-bundle.sh "$out" /bin/hello
