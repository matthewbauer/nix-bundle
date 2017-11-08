{ stdenv, fetchurl, fuse, zlib, squashfsTools, glib }:

# This is from some binaries.

# Ideally, this should be source based,
# but I can't get it to build from GitHub

stdenv.mkDerivation rec {
  name = "appimagekit";

  src = fetchurl {
    url = "https://github.com/probonopd/AppImageKit/releases/download/7/appimagetool-x86_64.AppImage";
    sha256 = "1irvbf0xnya16cyzpvr43jviq5ly3wl7b9753rji7d1hhxwb7b9r";
  };

  buildInputs = [
    squashfsTools
  ];

  sourceRoot = "squashfs-root";

  unpackPhase = ''
    cp $src appimagetool-x86_64.AppImage
    chmod u+wx appimagetool-x86_64.AppImage
    patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
             --set-rpath ${fuse}/lib:${zlib}/lib \
             appimagetool-x86_64.AppImage
    ./appimagetool-x86_64.AppImage --appimage-extract
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out

    patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
         --set-rpath ${stdenv.glibc.out}/lib:${fuse}/lib:${zlib}/lib:${glib}/lib \
	 $out/bin/appimagetool
    patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
         --set-rpath ${zlib}/lib \
	 $out/bin/mksquashfs
  '';

  dontStrip = true;
  dontPatchELF = true;
}
