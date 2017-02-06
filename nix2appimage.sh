#!/usr/bin/env sh

if [ "$#" -lt 1 ]; then
    cat <<EOF

Usage: $0 TARGET

Create a single-file bundle from the nixpkgs attribute "TARGET".

For example:

$ $0 emacs
$ ./emacs

EOF

    exit 1
fi

target="$1"

expr="with import <nixpkgs> {}; with import ./. {}; appimage (appdir { name = \"$target\"; target = $target; })"

out=$(nix-store --no-gc-warning -r $(nix-instantiate --no-gc-warning -E "$expr"))

cp -f $out $target
