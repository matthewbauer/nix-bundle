{ stdenv, perl, pathsFromGraph }:

{ name, toplevel }:

  stdenv.mkDerivation {
    inherit toplevel name;
    exportReferencesGraph = [ "closure" toplevel ];
    buildInputs = [ perl ];
    buildCommand = ''
      storePaths=$(${perl}/bin/perl ${pathsFromGraph} ./closure)
      mkdir -p $out
      for path in $storePaths; do
        cp --parents -r $path $out/
      done
    '';
  }
