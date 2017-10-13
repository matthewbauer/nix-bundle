#!/bin/sh

if [ -z "$1" ]; then
    >&2 echo "Need more than one argument."
    >&2 echo "Try: $ nix-run hello"
    exit 1
fi

pkg=$1
shift

if ! [ -z "$1" ]; then
    name="$1"
    shift
else
    name="$pkg"
fi

expr="with import <nixpkgs> {}; let x = $pkg; in x"
path=$(nix-instantiate --no-gc-warning -E "$expr")
out=$(nix-store --no-gc-warning -r $path)

if [ -z "$out" ]; then
    >&2 echo "Could not evaluate $pkg to a Nix drv."
    exit 1
fi

run_darwin_app() {
    app="$1"
    shift
    echo 'darwin'
    open -a "$app" --args $@
}

run_linux_desktop_app() {
    # taken from:
    # https://askubuntu.com/questions/5172/running-a-desktop-file-in-the-terminal/5174#5174

    desktop="$1"
    shift
    cmd=$(grep '^Exec' $desktop | tail -1 | \
              sed 's/Exec=//;s/^"//;s/" *$/')
    if ! [ -z "$@" ]; then
        cmd=$(echo "$cmd" | sed "s/%[fu]/$1/;s/%[FU]/$@/")
    fi
    cmd=$(echo "$cmd" | sed "s/%k/$desktop/;s/%.//")
}

run_bin () {
    bin="$1"
    shift
    $bin $@
}

if [ "$(uname)" = Darwin ] && [ -d "$out/Applications/$name.app" ]; then
    run_darwin_app "$out/Applications/$name.app" $@
elif [ "$(uname)" = Darwin ] && [ -d $out/Applications/*.app ]; then
    for f in $out/Applications/*.app; do
        run_darwin_app "$f" $@
    done
elif [ -f "$out/share/applications/$name.desktop" ]; then
    run_linux_desktop_app "$out/share/applications/$name.desktop" $@
elif [ -d $out/share/applications ]; then
    for f in $out/share/applications/*.desktop; do
        run_linux_desktop_app "$f"
    done
elif [ -x "$out/bin/$name" ]; then
    run_bin "$out/bin/$name" $@
elif [ -d "$out/bin" ]; then
    for bin in $out/bin/*; do
        run_bin "$bin" $@
    done
else
    >&2 echo "Cannot find a way to run path $out."
    exit 1
fi
