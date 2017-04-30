{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

rec {
  appimagetool = callPackage ./appimagetool.nix {};

  appimage = callPackage ./appimage.nix {
    inherit appimagetool;
  };

  appdir = callPackage ./appdir.nix {};
}
