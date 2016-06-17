{ stdenv, writeText, nix-user-chroot, bash, makebootstrap }:

{ name, target, run }:

  makebootstrap {
    inherit name;
    startup = ".${nix-user-chroot}/bin/nix-user-chroot ./nix .${bash}/bin/sh -c ${target}${run}";
    targets = [ nix-user-chroot target bash ];
  }
