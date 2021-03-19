# nix-bundle

nix-bundle is a way to package Nix attributes into single-file executables.

## Benefits

* Single-file output
* Can be run by non-root users
* No runtime
* Distro agnostic
* No installation

## Getting started

Make sure you have installed Nix already. See http://nixos.org/nix/ for more details.

Once you have a working Nix install, you can run:

```sh
$ ./nix-bundle.sh hello /bin/hello
```

```hello``` indicates the Nix derivation from NixPkgs that you want to use, while ```/bin/hello``` indicates the path of the executable relative to ```hello``` that you want to run. This will create the file "hello". Running it:

```sh
$ ./hello
Hello, world!
```

This is a standalone file that is completely portable! As long as you are running the same architecture Linux kernel and have a shell interpreter available it will run.

Some others to try:

```sh
./nix-bundle.sh nano /bin/nano
```

```sh
./nix-bundle.sh emacs /bin/emacs
```

Or if you want to try graphical applications:

```sh
# Simple X game. Very few dependencies. Quick to build and load. ~13MB
./nix-bundle.sh xskat /bin/xskat
```

```sh
./nix-bundle.sh firefox /bin/firefox
```

```sh
# SDL-based game. ~228MB
./nix-bundle.sh ivan /bin/ivan
```


## Self-bundling (meta)

Starting with v0.1.3, you can bundle nix-bundle! To do this, just use nix-bundle normally:

```sh
NIX_PATH="nixpkgs=https://github.com/matthewbauer/nixpkgs/archive/nix-bundle.tar.gz" ./nix-bundle.sh nix-bundle /bin/nix-bundle
```

## [Experimental] Create AppImage executables from Nix expressions

"nix-bundle.sh" tends to create fairly large outputs. This is largely because nix-bundle.sh "extracts" its payload up front. AppImage uses a different method where extraction only takes place when the file is accessed (through FUSE and SquashFS). You can now create a compliant "AppImage" using the "nix2appimage.sh" script:

```sh
./nix2appimage.sh emacs
```

This will create a file at Emacs-x86_64.AppImage which you can execute.

Notice that there is only one argument for nix2appimage.sh. This is because the target executable will be detected from the .desktop file in ```/share/applications/*.desktop```. If there is no .desktop file, nix2appimage will attempt to create one. If, however, there are more than one executable in the bin/ directory, we can't pick one, and there will have to be a .desktop file.

Some other examples to try:

```sh
./nix2appimage.sh firefox
```

```sh
./nix2appimage.sh vlc
```

```sh
./nix2appimage.sh 0ad
```

```sh
./nix2appimage.sh wireshark-gtk
```

These may take a while because of the large closure size.

Note that these do not currently work out of the box with NixOS (but can be run through the `appimage-run` command). Other Linux distros should work. An additional limitation is that the machine running the AppImage must have a glibc at least as new as the one used to compile, so it is usually a good idea to pull an old version of glibc for your compilation.

If you are using flakes, nix-bundle exports the overlay `nix-bundle.overlays.glibc_2_24.${system}` for this purpose, which will pull in glibc 2.24, and will thus be compatible with almost every popular distro's supported releases. Be forewarned that this has to rebuild pretty much everything in nixpkgs and takes a *long* time. Also note that some packages (e.g. Firefox) do their own glibc versioning, and so don't need this; better to test your package on an old distro without this overlay first.

## Comparison with AppImage, FlatPak, Snappy

| Name       | Distro-agnostic | Runtime required | Root required | Storage |
| ---------- | --------------- | ---------------- | ------------- | ------- |
| nix-bundle | yes | no  | no  | Arx tarball                    | 
| AppImage   | yes | no  | no  | Squashfs w/ lzma compression   |
| FlatPak    | yes | yes | no  | ?                              |
| Snappy     | yes | yes | no  | squashFS                       |

## How it works

Nix-bundle glues together four different projects to work correctly:

* [Arx](https://github.com/solidsnack/arx) - an archive execution tool
* Creates single-file archive executable that can unpack themselves and then run some command. nix-bundle calls nix-user-chroot to bootstrap the Nix environment. It outputs a "./nix" folder.
* [nix-user-chroot](https://github.com/lethalman/nix-user-chroot) - a small bootstrap that uses Linux namespaces to call chroot
  * This will create sub namespace and bind mount the "./nix" to "/nix" so that the Nix references function properly.
* [Nix](https://nixos.org/nix/) - a functional package manager
  * Used to build runtime closures that are self-contained.
* [nixpkgs](https://nixos.org/nixpkgs/)
  * Provides lots of different packages to choose from.

## Drawbacks

Nix-bundle has some drawbacks that need to be worked on:

* Slow startup
* Large files (Firefox 150MB)
* Only compatible Linux
* Outputs built on x86-64 will not run on i386
* Requires Linux kernel with CAP_SYS_USER_NS on and permissions setup correctly
