{ stdenv, perl, pathsFromGraph }:

{ name, target }:

  stdenv.mkDerivation {
    inherit name;
    exportReferencesGraph = [ "closure" target ];
    nativeBuildInputs = [ perl ];
    buildCommand = ''
      storePaths=$(${perl}/bin/perl ${pathsFromGraph} ./closure)
      printRegistration=1 ${perl}/bin/perl ${pathsFromGraph} ./closure > .reginfo
      tar cvfj $out \
        --owner=0 --group=0 --mode=u+rw,uga+r \
        --hard-dereference \
        .reginfo $storePaths
    '';
  }
