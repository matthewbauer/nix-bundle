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

## [Experimental] Create AppImage executables from Nix expressions

"nix-bundle.sh" tends to create fairly large outputs. This is largely because nix-bundle.sh uses gzip compression and AppImage uses lzma compression. Anyway, you can create a compliant "AppImage" using the "nix2appimage.sh" script:

```sh
./nix2appimage.sh emacs
```

Notice that there is only one argument for nix2appimage.sh. This is because the target executable will be detected from the .desktop file in ```/share/applications/*.desktop```. As a side-effect, AppImage requires your package to have a .desktop file, so packages like "hello", "coreutils", etc. will not work.

Some other examples to try:

```sh
./nix2appimage.sh firefox
./nix2appimage.sh vlc
./nix2appimage.sh allegro
```

These may take a while because of the large closure size.

## Comparison with AppImage, FlatPak, Snappy

| Name       | Distro-agnostic | Runtime required | Root required | Storage | Packaged size of vlc |
| ---------- | --------------- | ---------------- | ------------- | ------- | -------------------- |
| nix-bundle | yes | no  | no  | Arx tarball                    | 176M | 
| AppImage   | yes | no  | no  | Squashfs w/ lzma compression   | 80M  |
| FlatPak    | yes | yes | no  | ?                              | ?    |
| Snappy     | yes | yes | no  | squashFS                       | 115M |

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
