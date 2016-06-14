{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

let

  makeself = callPackage ./makeself.nix {};
  makedir = callPackage ./makedir.nix {};

in

  { name, target, run }:
    makeself {
      inherit name;
      startup = ".${target}${run}";
      archive = makedir {
        name = "${name}-dir";
        toplevel = target;
      };
    }
