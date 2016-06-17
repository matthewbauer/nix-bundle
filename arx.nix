{ stdenv, arx }:

{ name
, archive
, startup
}:

  stdenv.mkDerivation {
    inherit name;
    nativeBuildInputs = [ arx ];
    buildCommand = ''
      ${arx}/bin/arx tmpx ${archive} -o $out // ${startup}
      chmod +x $out
    '';
  }
