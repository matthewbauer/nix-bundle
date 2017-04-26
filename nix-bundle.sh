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

nix_file=`dirname $0`/default.nix

expr="with import <nixpkgs> {}; with import $nix_file {}; nix-bootstrap { target = $target; run = \"$exec\"; }"

out=$(nix-store --no-gc-warning -r $(nix-instantiate --no-gc-warning -E "$expr"))

if [ -z "$out" ]; then
  >&2 echo "$0 failed. Exiting."
  exit 1
elif [ -t 1 ]; then
  filename=$(basename $exec)
  echo "Nix bundle created at $filename."
  cp -f $out $filename
else
  cat $out
fi
