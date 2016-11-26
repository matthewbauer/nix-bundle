{ stdenv, writeText, nix-user-chroot, makebootstrap }:
{ name, target, run }:

makebootstrap {
  inherit name;
  startup = ".${nix-user-chroot}/bin/nix-user-chroot ./nix ${target}${run}";
  targets = [ nix-user-chroot target ];
}
