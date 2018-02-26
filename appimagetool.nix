{ stdenv, fetchurl, fuse, zlib, squashfsTools, glib }:

# This is from some binaries.

# Ideally, this should be source based,
# but I can't get it to build from GitHub

let
  inherit (stdenv.cc.bintools) dynamicLinker;
in stdenv.mkDerivation rec {
  name = "appimagekit";

  src = fetchurl {
    url = "https://github.com/AppImage/AppImageKit/releases/download/10/appimagetool-x86_64.AppImage";
    sha256 = "03zbiblj8a1yk1xsb5snxi4ckwn3diyldg1jh5hdjjhsmpw652ig";
  };

  buildInputs = [
    squashfsTools
  ];

  sourceRoot = "squashfs-root";

  unpackPhase = ''
    cp $src appimagetool-x86_64.AppImage
    chmod u+wx appimagetool-x86_64.AppImage
    patchelf --set-interpreter ${dynamicLinker} \
             --set-rpath ${fuse}/lib:${zlib}/lib \
             appimagetool-x86_64.AppImage
    ./appimagetool-x86_64.AppImage --appimage-extract
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out

    patchelf --set-interpreter ${dynamicLinker} \
         --set-rpath ${stdenv.glibc.out}/lib:${fuse}/lib:${zlib}/lib:${glib}/lib \
	 $out/bin/appimagetool
    patchelf --set-interpreter ${dynamicLinker} \
         --set-rpath ${zlib}/lib \
	 $out/bin/mksquashfs
  '';

  dontStrip = true;
  dontPatchELF = true;
}
