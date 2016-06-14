{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

let

  makebootstrap = callPackage ./makebootstrap.nix {};
  install-nix-from-closure = callPackage ./install-nix-from-closure.nix {};

in makebootstrap {
  name = "nix-bootstrap.sh";
  target = install-nix-from-closure;
  run = "/install";
}
