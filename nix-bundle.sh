#!/usr/bin/env sh

fail() {
    echo "Try '$0 --help'." >&2
    exit 2
}

build() {
    linkdir=$(mktemp -d)
    nix build "$@" --out-link "$linkdir/result"
    readlink "$linkdir/result"
}

check_arg() {
    if [ $# -le 1 ]
    then
        echo "error: flag '$1' requires an argument" >&2
        fail
    fi
}

nix_file=`dirname $0`/default.nix

# Read arguments

build_flags=()
unset bin
targets=()

while [ $# -ne 0 ]
do
    case "$1" in
        -f|--file|-I|--include)
            check_arg "$@"
            build_flags+=("$1")
            shift
            build_flags+=("$1")
            shift
            ;;
        --arg|--argstr)
            if [ $# -le 2 ]
            then
                echo "error: flag '$1' requires two arguments" >&2
                fail
            fi
            build_flags+=("$1")
            shift
            build_flags+=("$1")
            shift
            build_flags+=("$1")
            shift
            ;;
        --bin)
            check_arg "$@"
            shift
            bin="$1"
            shift
            ;;
        -h|--help)
            cat <<EOF >&2
Usage: $0 <FLAGS>... [<TARGET>] <targets>...

Summary: Similar to nix build, but creates a single-file bundle.

Flags:
      --arg <NAME> <EXPR>       argument to be passed to Nix functions
      --argstr <NAME> <STRING>  string-valued argument to be passed to Nix functions
  -f, --file <FILE>             evaluate FILE rather than the default
  -I, --include <PATH>          add a path to the list of locations used to look up <...> file names
      --bin <BINARY>            the binary to bundle, relative to TARGET's output path

Examples:

  To bundle GNU Hello from NixOS 19.03:
  $ $0 -f channel:nixos-19.03 hello --bin /bin/hello

  To bundle the executable from within a project that has a default.nix for build:
  $ $0 --bin /bin/name-of-the-executable
EOF
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "error: unrecognized flag '$1'" >&2
            fail
            ;;
        *)
            targets+=("$1")
            shift
            ;;
    esac
done

while [ $# -ne 0 ]
do
    targets+=("$1")
    shift
done

# Check if all required arguments were passed

if [ -z ${bin+x} ]
then
    echo "error: flag '--bin' is required" >&2
    fail
fi

# Create tmp directory for the links produced by `nix build`

linkdir=$(mktemp -d)
build_flags+=("--out-link")
build_flags+=("$linkdir/result")

# Build targets

target_path=
extra_target_paths=

for target in "${targets[@]}"
do
    nix build "${build_flags[@]}" "$target" || exit $?
    if [ -z "$target_path" ]
    then
        target_path="$(readlink "$linkdir/result")"
    else
        extra_target_paths="$extra_target_paths $(readlink "$linkdir/result")"
    fi
done

if [ -z "$target_path" ]
then
    nix build "${build_flags[@]}" || exit $?
    target_path="$(readlink "$linkdir/result")"
fi

# Determine bootstrap function -- This seems like a total hack!

bootstrap=nix-bootstrap
if [ "${targets[0]}" = "nix-bundle" ] || [ "${targets[0]}" = "nixStable" ] || [ "${targets[0]}" = "nixUnstable" ] || [ "${targets[0]}" = "nix" ]; then
    bootstrap=nix-bootstrap-nix
elif ! [ -z "$extra_target_paths" ]; then
    bootstrap=nix-bootstrap-path
fi

# Run bootstrap function

expr="(with import $nix_file {}; $bootstrap { target = $target_path; extraTargets = [$extra_target_paths ]; run = \"$bin\"; })"

echo $expr

out=$(nix-store --no-gc-warning -r $(nix-instantiate --no-gc-warning -E "$expr"))

# Copy the created bundle to the working directory

if [ -z "$out" ]; then
  >&2 echo "$0 failed. Exiting."
  exit 1
elif [ -t 1 ]; then
  filename=$(basename $bin)
  echo "Nix bundle created at $filename."
  cp -f $out $filename
else
  cat $out
fi
