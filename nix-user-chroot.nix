{ stdenv, fetchFromGitHub, patchelf }:

stdenv.mkDerivation {
  name = "nix-user-chroot";
  phases = [ "buildPhase" "fixupPhase" "installPhase" ];

  buildPhase = ''
    cp ${./nix-user-chroot.c} nix-user-chroot.c
    $CC nix-user-chroot.c -o nix-user-chroot
  '';

  # setup local libc interpreter
  fixupPhase = ''
    patchelf --set-interpreter .$(patchelf --print-interpreter nix-user-chroot) nix-user-chroot
    patchelf --set-rpath $(patchelf --print-rpath nix-user-chroot | sed 's|/nix/store/|./nix/store/|g') nix-user-chroot
  '';

  installPhase = ''
    mkdir -p $out/bin/
    cp nix-user-chroot $out/bin/nix-user-chroot
  '';
}
