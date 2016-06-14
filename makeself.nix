{ stdenv, makeself }:

{ name
, archive
, startup
}:

  stdenv.mkDerivation {
    inherit name archive startup;
    nativeBuildInputs = [ makeself ];
    buildCommand = ''
      ${makeself}/bin/makeself $archive $out $name $startup
    '';
  }
