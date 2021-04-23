{ stdenv, appimagekit }:
dir:

stdenv.mkDerivation {
  name = "appimage";
  nativeBuildInputs = [ appimagekit ];
  buildCommand = ''
    appimagetool ${dir}/*.AppDir

    chmod +w *.AppImage
    patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 *.AppImage

    # shrink the closure (AppImage can't access /nix/store anyways)
    patchelf --set-rpath "" *.AppImage
    chmod -w *.AppImage

    mkdir $out
    cp *.AppImage $out
  '';
}
