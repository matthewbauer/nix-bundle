# nix-bundle

nix-bundle is a way to package Nix attributes into single-file executables.

## Benefits

* Single-file output
* Can be run by non-root users
* No runtime
* Distro agnostic
* Completely portable
* No installation

## Getting started

Make sure you have installed Nix already. See http://nixos.org/nix/ for more details.

Once you have a working Nix install, you can run:

```sh
$ ./nix-bundle.sh hello /bin/hello
```

This will create the file "hello". Running it:

```sh
$ ./hello
Hello, world!
```

This is a standalone file that is completely portable! As long as you are running a Linux kernel with the same architecture that you ran the command on it will run. No external dependencies are required besides a compatible Linux kernel.

Some others to try:

```sh
./nix-bundle.sh nano /bin/nano
```

```sh
./nix-bundle.sh firefox /bin/firefox
```

```sh
./nix-bundle.sh emacs /bin/emacs
```

## Comparison with AppImage, FlatPak, Snappy

TODO

## How it works

Nix-bundle glues together four different projects to work correctly:

* Nix - a functional package manager
* nixpkgs
* nix-user-chroot - a small bootstrap that uses Linux namespaces to 
* Arx - an archive execution tool

## Drawbacks

Nix-bundle has some drawbacks that need to be worked on:

* Slow startup
* Large files (Firefox 150MB)
* Only compatible Linux
* Outputs built on x86-64 will not run on i386
* Requires Linux kernel with CAP_SYS_USER_NS on and permissions setup correctly
