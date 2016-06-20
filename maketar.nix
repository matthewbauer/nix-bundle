{ stdenv, perl, pathsFromGraph }:

{ name, targets }:

  stdenv.mkDerivation {
    inherit name;
    exportReferencesGraph = map (x: [("closure-" + baseNameOf x) x]) targets;
    nativeBuildInputs = [ perl ];
    buildCommand = ''
      storePaths=$(${perl}/bin/perl ${pathsFromGraph} ./closure-*)
      # printRegistration=1 ${perl}/bin/perl ${pathsFromGraph} ./closure-* > .reginfo
      tar cvfj $out \
        --owner=0 --group=0 --mode=u+rw,uga+r \
        --hard-dereference \
        $storePaths
    '';
  }
