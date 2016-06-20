#!/usr/bin/env /sh

set -e

self="."
nix="@nix@"
cacert="@cacert@"

export SSL_CERT_FILE="$cacert/etc/ssl/certs/ca-bundle.crt"

if ! [ -e $self/.reginfo ]; then
    echo "$0: incomplete installer (.reginfo is missing)" >&2
    exit 1
fi

echo "initialising Nix database..." >&2
if ! $nix/bin/nix-store --init; then
    echo "$0: failed to initialize the Nix database" >&2
    exit 1
fi

if ! $nix/bin/nix-store --load-db < $self/.reginfo; then
    echo "$0: unable to register valid paths" >&2
    exit 1
fi

. $nix/etc/profile.d/nix.sh

if ! $nix/bin/nix-env -i "$nix"; then
    echo "$0: unable to install Nix into your default profile" >&2
    exit 1
fi

$nix/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
$nix/bin/nix-channel --update nixpkgs
