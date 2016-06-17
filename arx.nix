{ stdenv, arx }:

{ name
, archive
, startup
}:

  stdenv.mkDerivation {
    inherit name;
    nativeBuildInputs = [ arx ];
    buildCommand = ''
      ${arx}/bin/arx tmpx ${archive} -o $out -e ${startup}
      chmod +x $out
    '';
  }
