{ stdenv, appimagetool }:
dir:

stdenv.mkDerivation {
  name = "appimage";
  buildInputs = [ appimagetool ];
  buildCommand = ''
    appimagetool ${dir}/*.AppDir
    mkdir $out
    cp *.AppImage $out
  '';
}
