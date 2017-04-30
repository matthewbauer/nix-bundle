#!/bin/sh

cmd=sh
if ! [ $# -eq 0 ]; then
    cmd=$@
fi

# should download this in the future
# but the mirror is down
proot=`dirname $0`/proot-`uname -p`
export PROOT_NO_SECCOMP=1

if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi

if [ -z "$IN_PROOT" ]; then
    export IN_PROOT=1

    if ! [ -d $HOME/.nix ]; then
        mkdir -p $HOME/.nix
        s=$(mktemp)
        curl https://nixos.org/nix/install -o $s
        $proot -b $HOME/.nix:/nix $0 sh $s
    fi

    $proot -b $HOME/.nix:/nix $0 $cmd

    export IN_PROOT=
    exit
elif ! [ $# -eq 0 ]; then
    exec $cmd
fi
