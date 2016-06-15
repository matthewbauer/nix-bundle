{ stdenv, fetchFromGitHub }:

  stdenv.mkDerivation {
    name = "nix-user-chroot";
    buildCommand = ''
      cp ${./nix-user-chroot.c} nix-user-chroot.c
      mkdir -p $out/bin/
      cc nix-user-chroot.c -o $out/bin/nix-user-chroot
    '';
  }
