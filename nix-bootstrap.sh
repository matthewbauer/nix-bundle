#!/bin/sh

cmd=sh
if ! [ $# -eq 0 ]; then
    cmd=$@
fi

# should download this in the future
# but the mirror is down
proot=`dirname $0`/proot-`uname -p`
export PROOT_NO_SECCOMP=1

nixdir=$HOME/.nix

OLD_NIX_PATH=$NIX_PATH
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi
if ! [ -z "$OLD_NIX_PATH" ]; then NIX_PATH="$OLD_NIX_PATH"; fi

if [ -z "$IN_PROOT" ]; then
    export IN_PROOT=1

    if ! [ -d $nixdir ]; then
        mkdir -p $nixdir
        s=$(mktemp)
        curl https://nixos.org/nix/install -o $s
        $proot -b $nixdir:/nix $0 sh $s
    fi

    $proot -b $nixdir:/nix $0 $cmd

    export IN_PROOT=
    exit
elif ! [ $# -eq 0 ]; then
    exec $cmd
fi
