#!/bin/sh

pkg="$1"
shift
exe="$1"
shift
bin=$(mktemp)
out=$(mktemp)
~/nix.sh ./nix-bundle.sh $pkg $exe > $bin
chmod +x $bin
strace -f -o $out $bin $@
cat $out | grep -E '^[0-9]+ open\("\.?\/nix' | grep -Ev " = -[0-9]+ [A-Z]+ \([a-zA-Z ]+\)$" | sed -E 's/^[0-9]+ open\("\.?([^\"]+)".*/\1/'
