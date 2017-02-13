{ stdenv, perl, pathsFromGraph }:
{ targets }:

# everything in the closure linked together for inspection

stdenv.mkDerivation {
  name = "closure";
  exportReferencesGraph = map (x: [("closure-" + baseNameOf x) x]) targets;
  nativeBuildInputs = [ perl ];
  buildCommand = ''
    storePaths=$(${perl}/bin/perl ${pathsFromGraph} ./closure-*)

    mkdir $out
    ln -s $storePaths $out
  '';
}
