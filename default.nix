{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

let

  makeself = callPackage ./makeself.nix {};
  makedir = callPackage ./makedir.nix {};
  nix-bootstrap = callPackage ./nix-bootstrap.nix {};

  nixdir = makedir {
    name = "nixdir";
    toplevel = nix-bootstrap;
  };

in

  makeself {
    name = "nix-installer.sh";
    startup = ".${nix-bootstrap}/install";
    archive = nixdir;
  }
