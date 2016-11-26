{ stdenv, gcc, perl, pathsFromGraph }:
{ name, targets }:

stdenv.mkDerivation {
  inherit name;
  exportReferencesGraph = map (x: [("closure-" + baseNameOf x) x]) targets;
  nativeBuildInputs = [ perl ];
  buildCommand = ''
    storePaths=$(${perl}/bin/perl ${pathsFromGraph} ./closure-*)

    # remove "unused" stdenv store paths
    # these need to be adjusted and made more intelligent
    # this should create a "runtime stdenv"
    storePaths=$(echo $storePaths | tr ' ' '\n' | \
      grep -Ev '/nix/store/[a-z0-9]+-linux-headers-[0-9.]+' | \
      grep -v ${stdenv.cc.libc.dev} | \
      grep -v ${stdenv.cc.libc.bin} | \
      grep -v ${stdenv.cc.cc} | \
      grep -v ${stdenv.cc.cc.lib} | \
      tr '\n' ' ')
      # grep -Ev '/nix/store/[a-z0-9]+-zlib-[0-9.]+' | \

    # printRegistration=1 ${perl}/bin/perl ${pathsFromGraph} ./closure-* > .reginfo
    tar cfj $out \
      --owner=0 --group=0 --mode=u+rw,uga+r \
      --hard-dereference \
      $storePaths
  '';
}
