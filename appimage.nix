{ stdenv, appimagetool }:
dir:

stdenv.mkDerivation {
  name = "appimage.AppImage";
  buildInputs = [ appimagetool ];
  buildCommand = ''
    appimagetool ${dir} $out
  '';
}
