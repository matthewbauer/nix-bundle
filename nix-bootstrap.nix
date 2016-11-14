{ stdenv, writeText, proot, makebootstrap }:

{ name, target, run }:

  makebootstrap {
    inherit name;
    startup = ".${proot}/bin/proot -b./nix:/nix ${target}${run}";
    targets = [ proot target ];
  }
