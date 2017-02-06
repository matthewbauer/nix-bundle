{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

rec {

  arx = callPackage ./arx.nix {
    inherit (haskellPackages) arx;
  };

  maketar = callPackage ./maketar.nix {};

  nix-installer = callPackage ./nix-installer.nix {};

  makebootstrap = callPackage ./makebootstrap.nix {
    inherit arx maketar;
  };

  nix-user-chroot = callPackage ./nix-user-chroot.nix {};

  nix-bootstrap = callPackage ./nix-bootstrap.nix {
    inherit nix-user-chroot makebootstrap;
  };

  appimagetool = callPackage ./appimagetool.nix {};

  appimage = callPackage ./appimage.nix {
    inherit appimagetool;
  };

  appdir = callPackage ./appdir.nix {};
}
