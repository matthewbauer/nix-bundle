{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

let

  arx = callPackage ./arx.nix {
    inherit (haskellPackages) arx;
  };

  maketar = callPackage ./maketar.nix {};

  nix-installer = callPackage ./nix-installer.nix {};

  makebootstrap = callPackage ./makebootstrap.nix {
    inherit arx maketar;
  };

  nix-bootstrap = callPackage ./nix-bootstrap.nix {
    inherit makebootstrap;
  };

in {

  hello = nix-bootstrap {
    name = "hello";
    target = hello;
    run = "/bin/hello";
  };

  firefox = nix-bootstrap {
    name = "firefox";
    target = firefox;
    run = "/bin/firefox";
  };

  nano = nix-bootstrap {
    name = "nano";
    target = nano;
    run = "/bin/nano";
  };

  emacs = nix-bootstrap {
    name = "emacs";
    target = emacs;
    run = "/bin/emacs";
  };

  nixInstaller = makebootstrap {
    name = "nix-installer.sh";
    targets = [ nix-installer ];
    startup = ".${nix-installer}/install";
  };
}
