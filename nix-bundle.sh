#!/usr/bin/env sh

if [ "$#" -lt 2 ]; then
    cat <<EOF

Usage: $0 TARGET EXECUTABLE

Create a single-file bundle from the nixpkgs attribute "TARGET".
EXECUTABLE should be relative to the TARGET's output path.

For example:

$ $0 hello /bin/hello
$ ./hello
Hello, world!

EOF

    exit 1
fi

target="$1"
exec="$2"

expr="with import <nixpkgs> {}; with import ./. {}; nix-bootstrap { name = \"$target\"; target = $target; run = \"$exec\"; }"

out=$(nix-store -r $(nix-instantiate -E "$expr"))

cp -f $out $target
