{ stdenv, appimagetool }:
dir:

stdenv.mkDerivation {
  name = "appimage";
  buildInputs = [ appimagetool ];
  buildCommand = ''
    cp -r ${dir}/* .
    chmod +w *.AppDir
    ARCH=x86_64 appimagetool *.AppDir
    mkdir $out
    cp *.AppImage $out
  '';
}
