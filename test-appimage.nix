{ appimagefile, nixpkgs' ? <nixpkgs> }:

# nix build -f test-appimage.nix --arg appimagefile ./VLC*AppImage

with import nixpkgs' {};

runCommand "patchelf" {} ''
  cp ${appimagefile} $out
  chmod +w $out
  patchelf \
    --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
    --set-rpath ${stdenv.glibc.out}/lib:${fuse}/lib:${zlib}/lib:${glib}/lib \
    $out
''
