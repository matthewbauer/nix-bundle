{ stdenv, perl, pathsFromGraph }:

{ name, toplevel }:

  stdenv.mkDerivation {
    inherit toplevel name;
    exportReferencesGraph = [ "closure" toplevel ];
    buildInputs = [ perl ];
    buildCommand = ''
      mkdir -p $out
      storePaths=$(${perl}/bin/perl ${pathsFromGraph} ./closure)
      printRegistration=1 ${perl}/bin/perl ${pathsFromGraph} ./closure > $out/.reginfo
      for path in $storePaths; do
        cp --parents -rp $path $out/
      done
    '';
  }
