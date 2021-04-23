{ pkgs ? import <nixpkgs> { } }:

rec {
  appdir2appimage = pkgs.callPackage ./appimage.nix { };

  nix2appdir = pkgs.callPackage ./appdir.nix { };

  nix2appimage = x: appdir2appimage (nix2appdir x);

  appimage = nix2appimage;

  appdir = nix2appdir;
}
