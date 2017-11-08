{ stdenv, appimagetool }:
dir:

stdenv.mkDerivation {
  name = "appimage";
  buildInputs = [ appimagetool ];
  buildCommand = ''
    ARCH=x86_64 appimagetool ${dir}/*.AppDir
    mkdir $out
    cp *.AppImage $out
  '';
}
