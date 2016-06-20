{ stdenv, fetchFromGitHub }:

  stdenv.mkDerivation {
    name = "nix-user-chroot";
    phases = [ "buildPhase" "installPhase" "fixupPhase" ];
    buildPhase = ''
      cp ${./nix-user-chroot.c} nix-user-chroot.c
      $CC nix-user-chroot.c -o nix-user-chroot
    '';
    installPhase = ''
      mkdir -p $out/bin/
      cp nix-user-chroot $out/bin/nix-user-chroot
    '';
  }
