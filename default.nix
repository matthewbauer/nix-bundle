{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

let

  makeself = callPackage ./makeself.nix {};
  makedir = callPackage ./makedir.nix {};

  nix-bootstrap = callPackage ./nix-bootstrap.nix {};

  makebootstrap = {name, script}:
    makeself {
      inherit name;
      startup = ".${script}/install";
      archive = makedir {
        name = "${name}-dir";
	toplevel = script;
      };
    };

in makebootstrap {
  name = "nix-bootstrap.sh";
  script = nix-bootstrap;
}
