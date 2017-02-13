#!/usr/bin/env sh

target="$1"

expr="with import <nixpkgs> {}; with import ./. {}; closure { targets = [$target]; }"

nix-store --no-gc-warning -r $(nix-instantiate --no-gc-warning -E "$expr")
