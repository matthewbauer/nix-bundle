{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

let

  makeself = callPackage ./makeself.nix {};
  makedir = callPackage ./makedir.nix {};
  nix-installer = callPackage ./nix-installer.nix {};

  makebootstrap = callPackage ./makebootstrap.nix {
    inherit makedir makeself;
  };

  nix-user-chroot = callPackage ./nix-user-chroot.nix {};

  nix-bootstrap = callPackage ./nix-bootstrap.nix {
    inherit nix-user-chroot;
  };

in {

  versionTest = makebootstrap {
    name = "nix-bootstrap.sh";
    target = nix-bootstrap {
      name = "nix-bootstrap";
      stage3 = "nix-env --version";
    };
    run = "/stage1.sh";
  };

  nixInstaller = makebootstrap {
    name = "nix-installer.sh";
    target = nix-installer;
    run = "/install";
  };
}
