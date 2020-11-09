#!/bin/sh

# nix-run.sh provides an easy way to run executables from Nix derivations
# without installing them. It will try to determine how to run the application
# based on what files are installable. Currently, macOS apps, Freedesktop apps,
# and ordinary binaries are handled.

# Usage

if [ -z "$1" ]; then
    >&2 echo "Need more than one argument."
    >&2 echo
    >&2 echo "Try:"
    >&2 echo "$ nix-run hello"
    >&2 echo
    >&2 echo "To run the hello program"
    >&2 echo "or substitute hello with another package in Nixpkgs"
    exit 1
fi

pkg="$1"
shift

# A second argument will provide a hint to run
if [ -n "$1" ]; then
    name="$1"
    shift
else
    name="$pkg"
fi

expr="with import <nixpkgs> {}; let x = ($pkg); in x"
path=$(nix-instantiate --no-gc-warning -E "$expr")
out=$(nix-store --no-gc-warning -r "$path")

if [ -z "$out" ]; then
    >&2 echo "Could not evaluate $pkg to a Nix drv."
    exit 1
fi

# Run DIR as a Darwin application
run_darwin_app () {
    dir="$1"
    shift

    open -a "$dir" --args "$@"
}

# Run FILE as a Freedesktop application
# taken from:
# https://askubuntu.com/questions/5172/running-a-desktop-file-in-the-terminal/5174
run_linux_desktop_app () {
    file="$1"
    shift

    cmd=$(grep '^Exec' "$file" | tail -1 | \
              sed 's/Exec=//;s/^"//;s/" *$//')

    if [ "$#" -gt 0 ]; then
        cmd=$(echo "$cmd" | sed "s/%[fu]/$1/;s/%[FU]/$*/")
    fi

    cmd=$(echo "$cmd" | sed "s/%k/$desktop/;s/%.//")

    "$cmd" "$@"
}

# Run FILE as an ordinary binary
run_bin () {
    file="$1"
    shift

    "$file" "$@"
}

if [ -x "$out/nix-support/run" ]; then
    run_bin "$out/nix-support/run" "$@"
elif [ -x "$out/bin/run" ]; then
    run_bin "$out/bin/run" "$@"
elif [ "$(uname)" = Darwin ] && [ -d "$out/Applications/$name.app" ]; then
    run_darwin_app "$out/Applications/$name.app" "$@"
elif [ "$(uname)" = Darwin ] && [ -d "$out"/Applications/*.app ]; then
    for f in "$out"/Applications/*.app; do
        run_darwin_app "$f" "$@"
    done
elif [ -f "$out/share/applications/$name.desktop" ]; then
    run_linux_desktop_app "$out/share/applications/$name.desktop" "$@"
elif [ -d "$out"/share/applications ]; then
    for f in "$out"/share/applications/*.desktop; do
        run_linux_desktop_app "$f"
    done
elif [ -x "$out/bin/$name" ]; then
    run_bin "$out/bin/$name" "$@"
elif [ -d "$out/bin" ]; then
    for bin in "$out"/bin/*; do
        run_bin "$bin" "$@"
    done
else
    >&2 echo "Cannot find a way to run path $out."
    exit 1
fi
