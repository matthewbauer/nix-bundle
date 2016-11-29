{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "nix-user-chroot-2b144e";

  src = fetchFromGitHub {
    owner = "matthewbauer";
    repo = "nix-user-chroot";
    rev = "2b144ee89568ba40b66317da261ce889fbda3674";
    sha256 = "16bmshhvk6941w04rx78i5a1305876qni2n2rvm7rkziz49j158n";
  };

  postFixup = ''
    exe=$out/bin/nix-user-chroot
    patchelf \
      --set-interpreter .$(patchelf --print-interpreter $exe) \
      --set-rpath $(patchelf --print-rpath $exe | sed 's|/nix/store/|./nix/store/|g') \
      $exe
  '';

  installPhase = ''
    mkdir -p $out/bin/
    cp nix-user-chroot $out/bin/nix-user-chroot
  '';
}
